import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/logic/personal_color_judge.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/master_models.dart';

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

void main() {
  group('judgePersonalColor', () {
    test('暖寒軸と明深軸の交点でタイプが決まる', () {
      // 暖3-寒0 / 明0-深3 → イエベ かつ 深い = イエベ秋
      final questions = [
        question('q1', {
          'a': {'spring': 1, 'autumn': 2},
        }),
        question('q2', {
          'a': {'autumn': 1},
        }),
      ];

      final result = judgePersonalColor(
        questions: questions,
        answers: {'q1': 'a', 'q2': 'a'},
      );

      expect(result.type, PersonalColorType.autumn);
      expect(result.warmScore, 4);
      expect(result.coolScore, 0);
      expect(result.brightScore, 1);
      expect(result.deepScore, 3);
      expect(result.wasTie, isFalse);
    });

    test('タイプ単体の最高点ではなく、軸の合計で決まる', () {
      // 素点は summer が単独最高。しかし暖寒軸では暖4 > 寒3 なのでイエベ側に決まる。
      final questions = [
        question('q1', {
          'a': {'spring': 2, 'autumn': 2, 'summer': 3},
        }),
      ];

      final result = judgePersonalColor(questions: questions, answers: {'q1': 'a'});

      expect(result.typeScores[PersonalColorType.summer], 3);
      expect(result.warmScore, greaterThan(result.coolScore));
      expect(result.type, PersonalColorType.spring);
    });

    test('軸が同点なら、その軸を報告したうえでイエベ側・明るい側を採る', () {
      final questions = [
        question('q1', {
          'a': {'spring': 1, 'summer': 1},
        }),
      ];

      final result = judgePersonalColor(questions: questions, answers: {'q1': 'a'});

      expect(result.tiedAxes, [PersonalColorAxis.warmCool]);
      expect(result.wasTie, isTrue);
      expect(result.type, PersonalColorType.spring);
    });

    test('両軸が同点でも判定は返る', () {
      final questions = [
        question('q1', {'a': <String, int>{}}),
      ];

      final result = judgePersonalColor(questions: questions, answers: {'q1': 'a'});

      expect(result.tiedAxes, hasLength(2));
      expect(result.type, PersonalColorType.spring);
    });

    test('軸の差の小ささを取り出せる', () {
      final questions = [
        question('q1', {
          'a': {'spring': 3, 'summer': 2},
        }),
      ];

      final result = judgePersonalColor(questions: questions, answers: {'q1': 'a'});

      expect(result.warmCoolMargin, 1);
      expect(result.brightDeepMargin, 5);
    });

    test('4タイプすべてが判定されうる', () {
      final questions = [
        question('q1', {
          'warm': {'spring': 1, 'autumn': 1},
          'cool': {'summer': 1, 'winter': 1},
        }),
        question('q2', {
          'bright': {'spring': 1, 'summer': 1},
          'deep': {'autumn': 1, 'winter': 1},
        }),
      ];

      PersonalColorType judge(String a, String b) => judgePersonalColor(
            questions: questions,
            answers: {'q1': a, 'q2': b},
          ).type;

      expect(judge('warm', 'bright'), PersonalColorType.spring);
      expect(judge('warm', 'deep'), PersonalColorType.autumn);
      expect(judge('cool', 'bright'), PersonalColorType.summer);
      expect(judge('cool', 'deep'), PersonalColorType.winter);
    });
  });
}
