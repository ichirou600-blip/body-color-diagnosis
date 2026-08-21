import '../models/enums.dart';
import '../models/master_models.dart';
import 'diagnosis_scoring.dart';

/// パーソナルカラーの判定軸。
///
/// 4分類は独立した4つのタイプではなく、2つの軸の組み合わせでできている。
/// - 暖寒軸: イエベ（spring / autumn）⇔ ブルベ（summer / winter）
/// - 明深軸: 明るく澄んだ（spring / summer）⇔ 深い（autumn / winter）
enum PersonalColorAxis {
  /// イエベ寄りかブルベ寄りか。
  warmCool,

  /// 明るく澄んだ側か、深い側か。
  brightDeep,
}

/// パーソナルカラーの判定結果。
class PersonalColorJudgement {
  const PersonalColorJudgement({
    required this.type,
    required this.typeScores,
    required this.warmScore,
    required this.coolScore,
    required this.brightScore,
    required this.deepScore,
    required this.tiedAxes,
  });

  final PersonalColorType type;

  /// タイプごとの素点。結果画面の内訳表示などに使える。
  final Map<PersonalColorType, int> typeScores;

  final int warmScore;
  final int coolScore;
  final int brightScore;
  final int deepScore;

  /// 同点になった軸。空なら両軸とも差がついている。
  ///
  /// `questions.json` が `docs/DATA_SCHEMA.md` の配点ルールを守っていれば空になる。
  final List<PersonalColorAxis> tiedAxes;

  bool get wasTie => tiedAxes.isNotEmpty;

  /// 軸ごとの差の小ささ。0 に近いほど「どちらとも言える」判定。
  int get warmCoolMargin => (warmScore - coolScore).abs();
  int get brightDeepMargin => (brightScore - deepScore).abs();
}

/// パーソナルカラーを2軸方式で判定する。
///
/// タイプごとの合計点の最大値を採る方式だと、弱い手がかりが積み重なって
/// 決定的な手がかりを打ち消し、同点も頻発する（実測で全回答パターンの18.4%）。
/// 軸ごとに証拠をまとめてから交点を採ると、その両方が解消する。
///
/// 同点が起きた軸では、イエベ側・明るい側を採る。
/// `docs/DATA_SCHEMA.md` の配点ルール（各軸の総点を奇数にする）を守っていれば
/// 同点自体が起こらないので、これは保険。
PersonalColorJudgement judgePersonalColor({
  required List<Question> questions,
  required DiagnosisAnswers answers,
}) {
  final scored = scoreDiagnosis(
    questions: questions,
    candidates: PersonalColorType.values,
    idOf: (type) => type.id,
    answers: answers,
  );
  final scores = scored.scores;

  int scoreOf(PersonalColorType type) => scores[type] ?? 0;

  final warm = scoreOf(PersonalColorType.spring) + scoreOf(PersonalColorType.autumn);
  final cool = scoreOf(PersonalColorType.summer) + scoreOf(PersonalColorType.winter);
  final bright = scoreOf(PersonalColorType.spring) + scoreOf(PersonalColorType.summer);
  final deep = scoreOf(PersonalColorType.autumn) + scoreOf(PersonalColorType.winter);

  final isWarm = warm >= cool;
  final isBright = bright >= deep;

  final type = isWarm
      ? (isBright ? PersonalColorType.spring : PersonalColorType.autumn)
      : (isBright ? PersonalColorType.summer : PersonalColorType.winter);

  return PersonalColorJudgement(
    type: type,
    typeScores: scores,
    warmScore: warm,
    coolScore: cool,
    brightScore: bright,
    deepScore: deep,
    tiedAxes: [
      if (warm == cool) PersonalColorAxis.warmCool,
      if (bright == deep) PersonalColorAxis.brightDeep,
    ],
  );
}
