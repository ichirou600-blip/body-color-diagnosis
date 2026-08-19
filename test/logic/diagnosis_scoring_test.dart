import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/logic/diagnosis_scoring.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/master_models.dart';

/// テスト用に設問を組み立てる。`choices` は 選択肢ID → 配点。
Question question(String id, Map<String, Map<String, int>> choices) {
  return Question(
    id: id,
    text: id,
    choices: [
      for (final entry in choices.entries)
        Choice(id: entry.key, text: entry.key, scores: entry.value),
    ],
  );
}

DiagnosisResult<PersonalColorType> score(
  List<Question> questions,
  DiagnosisAnswers answers,
) {
  return scoreDiagnosis(
    questions: questions,
    candidates: PersonalColorType.values,
    idOf: (type) => type.id,
    answers: answers,
  );
}

void main() {
  group('scoreDiagnosis', () {
    test('合計点が最大のタイプが選ばれる', () {
      final questions = [
        question('q1', {
          'a': {'spring': 2},
          'b': {'winter': 2},
        }),
        question('q2', {
          'a': {'spring': 1, 'autumn': 1},
          'b': {'summer': 3},
        }),
      ];

      final result = score(questions, {'q1': 'a', 'q2': 'a'});

      expect(result.type, PersonalColorType.spring);
      expect(result.scores[PersonalColorType.spring], 3);
      expect(result.scores[PersonalColorType.autumn], 1);
      expect(result.scores[PersonalColorType.winter], 0);
      expect(result.wasTie, isFalse);
    });

    test('選ばなかった選択肢の配点は加算されない', () {
      final questions = [
        question('q1', {
          'a': {'spring': 5},
          'b': {'winter': 1},
        }),
      ];

      final result = score(questions, {'q1': 'b'});

      expect(result.type, PersonalColorType.winter);
      expect(result.scores[PersonalColorType.spring], 0);
    });

    test('同点なら候補の並び順が先のタイプを採用し、同点だったことを残す', () {
      final questions = [
        question('q1', {
          'a': {'summer': 1, 'autumn': 1},
        }),
      ];

      final result = score(questions, {'q1': 'a'});

      expect(result.type, PersonalColorType.summer);
      expect(result.tiedTypes, [PersonalColorType.summer, PersonalColorType.autumn]);
      expect(result.wasTie, isTrue);
    });

    test('全員0点でも先頭のタイプを返して落ちない', () {
      final questions = [
        question('q1', {'a': <String, int>{}}),
      ];

      final result = score(questions, {'q1': 'a'});

      expect(result.type, PersonalColorType.spring);
      expect(result.wasTie, isTrue);
      expect(result.tiedTypes, hasLength(4));
    });

    test('スコアには候補すべてのキーが入る', () {
      final result = score([
        question('q1', {
          'a': {'spring': 1},
        }),
      ], {'q1': 'a'});

      expect(result.scores.keys, containsAll(PersonalColorType.values));
    });

    test('未回答があれば例外。どの設問が未回答か分かる', () {
      final questions = [
        question('q1', {
          'a': {'spring': 1},
        }),
        question('q2', {
          'a': {'summer': 1},
        }),
      ];

      expect(
        () => score(questions, {'q1': 'a'}),
        throwsA(
          isA<IncompleteDiagnosisException>().having(
            (e) => e.unansweredQuestionIds,
            'unansweredQuestionIds',
            ['q2'],
          ),
        ),
      );
    });

    test('設問に存在しない選択肢IDは例外にする', () {
      final questions = [
        question('q1', {
          'a': {'spring': 1},
        }),
      ];

      expect(() => score(questions, {'q1': 'zzz'}), throwsArgumentError);
    });

    test('骨格タイプでも同じロジックで集計できる', () {
      final questions = [
        question('k1', {
          'a': {'natural': 2},
          'b': {'wave': 1},
        }),
      ];

      final result = scoreDiagnosis(
        questions: questions,
        candidates: KokkakuType.values,
        idOf: (type) => type.id,
        answers: {'k1': 'a'},
      );

      expect(result.type, KokkakuType.natural);
    });
  });
}
