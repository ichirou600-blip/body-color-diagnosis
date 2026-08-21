import '../data/master_data.dart';
import '../models/enums.dart';

/// 相性診断の結果。
class CompatibilityResult {
  const CompatibilityResult({
    required this.myZodiac,
    required this.partnerZodiac,
    required this.text,
  });

  final Zodiac myZodiac;
  final Zodiac partnerZodiac;

  /// `compatibility.json` の相性テキスト。
  final String text;

  /// 同じ星座同士か。
  bool get isSameZodiac => myZodiac == partnerZodiac;
}

/// 相手の誕生日から星座を出して、相性テキストを引く。
///
/// 星座の組は順序を持たないので、自分と相手を入れ替えても同じ結果になる
/// （`docs/DATA_SCHEMA.md` の `compatibility.json` を参照）。
///
/// **相手の誕生日は保存しない。**入力されたその場で星座に変換して捨てる
/// （`docs/SPEC.md` §5 / `CLAUDE.md` の「絶対に破らないルール」1）。
CompatibilityResult? judgeCompatibility({
  required MasterData masters,
  required Zodiac myZodiac,
  required DateTime partnerBirthday,
}) {
  final partnerZodiac = Zodiac.fromDate(partnerBirthday);
  final text = masters.compatibilityTextFor(myZodiac, partnerZodiac);
  if (text == null) return null;
  return CompatibilityResult(
    myZodiac: myZodiac,
    partnerZodiac: partnerZodiac,
    text: text,
  );
}
