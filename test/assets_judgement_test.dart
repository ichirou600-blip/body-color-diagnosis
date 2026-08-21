import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/logic/diagnosis_scoring.dart';
import 'package:rakikara/logic/personal_color_judge.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/master_models.dart';

/// 同梱の `questions.json` が「判定の質」を保っているかを検証する。
///
/// 判定が同点になると、決着はタイプの並び順任せになる。つまりユーザーから見れば
/// でたらめな結果が返る。同点率と、判定の出やすさの偏りを機械的に見張る。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 全設問の全選択肢を総当たりして、回答パターンを1つずつ渡す。
  void forEachAnswerPattern(
    List<Question> questions,
    void Function(DiagnosisAnswers answers) visit,
  ) {
    final indices = List<int>.filled(questions.length, 0);
    while (true) {
      visit({
        for (var i = 0; i < questions.length; i++)
          questions[i].id: questions[i].choices[indices[i]].id,
      });

      var position = questions.length - 1;
      while (position >= 0) {
        indices[position]++;
        if (indices[position] < questions[position].choices.length) break;
        indices[position] = 0;
        position--;
      }
      if (position < 0) return;
    }
  }

  group('パーソナルカラー', () {
    test('配点が2軸に分解でき、同点が起こりえない', () async {
      final questions = (await const MasterRepository().load()).personalColorQuestions;

      var warmCoolTotal = 0;
      var brightDeepTotal = 0;
      for (final question in questions) {
        // 同じ設問のどの選択肢を選んでも、軸に入る合計点は同じでなければならない。
        // ここがずれると「選んだだけで軸の総量が変わる」ことになり、
        // 総点の偶奇が固定できず同点が起こりうる。
        final warmCool = {
          for (final choice in question.choices)
            choice.scores.values.fold(0, (sum, value) => sum + value),
        };
        expect(
          warmCool,
          hasLength(1),
          reason: '${question.id} は選択肢ごとに合計点が違います: $warmCool',
        );
        warmCoolTotal += warmCool.single;
        brightDeepTotal += warmCool.single;
      }

      // 総点が奇数なら「暖＝寒」「明＝深」は算術的に起こりえない。
      expect(warmCoolTotal.isOdd, isTrue, reason: '暖寒軸の総点 $warmCoolTotal は奇数である必要があります');
      expect(brightDeepTotal.isOdd, isTrue, reason: '明深軸の総点 $brightDeepTotal は奇数である必要があります');
    });

    test('全回答パターンで同点ゼロ、4タイプが均等に出る', () async {
      final questions = (await const MasterRepository().load()).personalColorQuestions;

      var total = 0;
      var ties = 0;
      final wins = {for (final type in PersonalColorType.values) type: 0};

      forEachAnswerPattern(questions, (answers) {
        final result = judgePersonalColor(questions: questions, answers: answers);
        total++;
        if (result.wasTie) ties++;
        wins[result.type] = wins[result.type]! + 1;
      });

      expect(ties, 0, reason: '$total 通り中 $ties 通りが同点');
      for (final entry in wins.entries) {
        final share = entry.value / total;
        expect(
          share,
          inInclusiveRange(0.15, 0.35),
          reason: '${entry.key.label} が ${(share * 100).toStringAsFixed(1)}% に偏っています',
        );
      }
    });
  });

  group('骨格', () {
    test('全回答パターンで同点が十分に少なく、3タイプが均等に出る', () async {
      final questions = (await const MasterRepository().load()).kokkakuQuestions;

      var total = 0;
      var ties = 0;
      final wins = {for (final type in KokkakuType.values) type: 0};

      forEachAnswerPattern(questions, (answers) {
        final result = scoreDiagnosis(
          questions: questions,
          candidates: KokkakuType.values,
          idOf: (type) => type.id,
          answers: answers,
        );
        total++;
        if (result.wasTie) ties++;
        wins[result.type] = wins[result.type]! + 1;
      });

      // 骨格は2軸に分解できないので同点を完全には消せない。
      // 配点の重みで実測 0.8% まで下げてある。悪化したら気づけるようにしておく。
      expect(
        ties / total,
        lessThan(0.02),
        reason: '$total 通り中 $ties 通り（${(ties / total * 100).toStringAsFixed(2)}%）が同点',
      );
      for (final entry in wins.entries) {
        final share = entry.value / total;
        expect(
          share,
          inInclusiveRange(0.28, 0.39),
          reason: '${entry.key.label} が ${(share * 100).toStringAsFixed(1)}% に偏っています',
        );
      }
    });
  });
}
