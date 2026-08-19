import '../models/enums.dart';
import '../models/master_models.dart';

/// 読み込み済みの静的マスタ一式と、その参照メソッド。
///
/// 掛け合わせエンジン（`docs/SPEC.md` §6）の入力になる「マスタ群」はこれ。
class MasterData {
  MasterData({
    required List<ColorItem> colors,
    required Map<PersonalColorType, TypeAttribute> personalColorAttributes,
    required Map<KokkakuType, TypeAttribute> kokkakuAttributes,
    required List<PcKokkakuStyle> pcKokkakuStyles,
    required List<CompatibilityEntry> compatibilityEntries,
    required List<Question> personalColorQuestions,
    required List<Question> kokkakuQuestions,
  })  : colors = List.unmodifiable(colors),
        personalColorAttributes = Map.unmodifiable(personalColorAttributes),
        kokkakuAttributes = Map.unmodifiable(kokkakuAttributes),
        personalColorQuestions = List.unmodifiable(personalColorQuestions),
        kokkakuQuestions = List.unmodifiable(kokkakuQuestions),
        _colorsById = {for (final color in colors) color.id: color},
        _stylesByPair = {
          for (final style in pcKokkakuStyles)
            _styleKey(style.pcType, style.kokkakuType): style,
        },
        _compatibilityByPair = {
          for (final entry in compatibilityEntries) entry.key: entry,
        };

  final List<ColorItem> colors;
  final Map<PersonalColorType, TypeAttribute> personalColorAttributes;
  final Map<KokkakuType, TypeAttribute> kokkakuAttributes;
  final List<Question> personalColorQuestions;
  final List<Question> kokkakuQuestions;

  final Map<String, ColorItem> _colorsById;
  final Map<String, PcKokkakuStyle> _stylesByPair;
  final Map<String, CompatibilityEntry> _compatibilityByPair;

  static String _styleKey(PersonalColorType pc, KokkakuType kokkaku) =>
      '${pc.id}|${kokkaku.id}';

  /// 色IDから色を引く。未知のIDなら null。
  ColorItem? colorById(String id) => _colorsById[id];

  /// そのPCタイプに似合う色の一覧。`type_attributes.json` の `color_ids` 順。
  List<ColorItem> colorsForPersonalColor(PersonalColorType pc) {
    final attribute = personalColorAttributes[pc];
    if (attribute == null) return const [];
    return [
      for (final id in attribute.colorIds) ?_colorsById[id],
    ];
  }

  /// PC×骨格の「似合うスタイル」テキスト。未登録の組み合わせなら null。
  String? styleTextFor(PersonalColorType pc, KokkakuType kokkaku) =>
      _stylesByPair[_styleKey(pc, kokkaku)]?.styleText;

  /// 星座相性テキスト。組の順序は問わない。未登録なら null。
  String? compatibilityTextFor(Zodiac a, Zodiac b) =>
      _compatibilityByPair[CompatibilityEntry.pairKey(a, b)]?.text;

  /// 本コンテンツが揃っているか（`docs/SPEC.md` §5 の想定件数）。
  ///
  /// 起動時には検証しない。仮データのままでもアプリは動く必要があるため。
  /// 揃っていない項目の説明を返す。空リストなら本データが揃っている。
  List<String> missingContentReport() {
    final issues = <String>[];
    if (colors.length != 40) {
      issues.add('色マスタが ${colors.length} 件（想定40件）');
    }
    final expectedStyles = PersonalColorType.values.length * KokkakuType.values.length;
    if (_stylesByPair.length != expectedStyles) {
      issues.add('PC×骨格が ${_stylesByPair.length} 件（想定$expectedStyles件）');
    }
    const expectedPairs = 78; // 12×13÷2（同星座同士を含む順序なしペア）
    if (_compatibilityByPair.length != expectedPairs) {
      issues.add('星座相性が ${_compatibilityByPair.length} 件（想定$expectedPairs件）');
    }
    if (personalColorQuestions.length != 10) {
      issues.add('PC診断が ${personalColorQuestions.length} 問（想定10問）');
    }
    if (kokkakuQuestions.length != 10) {
      issues.add('骨格診断が ${kokkakuQuestions.length} 問（想定10問）');
    }
    return issues;
  }
}
