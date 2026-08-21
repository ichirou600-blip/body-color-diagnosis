import '../data/master_data.dart';
import '../models/daily_fortune.dart';
import '../models/master_models.dart';
import '../models/user_profile.dart';
import 'rakuten_search.dart';

/// 掛け合わせルールへの入力。`docs/SPEC.md` §6 で固定したインターフェース。
class SuggestionContext {
  const SuggestionContext({
    required this.profile,
    required this.fortune,
    required this.masters,
  });

  final UserProfile profile;
  final DailyFortune fortune;
  final MasterData masters;
}

/// 掛け合わせルールの出力。画面はこのリストを並べるだけ。
class SuggestionCard {
  const SuggestionCard({
    required this.ruleId,
    required this.title,
    required this.body,
    this.color,
    this.searchUrl,
    this.highlighted = false,
  });

  /// どのルールが出したカードか。増えたときの切り分け用。
  final String ruleId;

  final String title;
  final String body;

  /// 色玉を出すための色。色に紐づかない提案なら null。
  final ColorItem? color;

  /// 楽天の検索リンク。
  final Uri? searchUrl;

  /// 今日いちばんの推し。占いの `lucky_item_category` と一致したカードに立つ。
  final bool highlighted;
}

/// 掛け合わせルール1つ。
///
/// **新しい掛け合わせを足すときは、この形の関数を1つ書いて
/// [SuggestionEngine.defaultRules] に足すだけでよい**（`docs/SPEC.md` §6）。
/// 画面もコンテンツも触らずに増やせる構造を崩さないこと。
typedef SuggestionRule = List<SuggestionCard> Function(SuggestionContext context);

/// ルールを順に適用して提案カードを並べる。
class SuggestionEngine {
  const SuggestionEngine({this.rules = defaultRules});

  static const List<SuggestionRule> defaultRules = [todayRecommend];

  final List<SuggestionRule> rules;

  List<SuggestionCard> run(SuggestionContext context) => [
        for (final rule in rules) ...rule(context),
      ];
}

/// 今日のおすすめ。PCの似合う色と今日のラッキーカラーを突き合わせる。
///
/// - 一致: そのラッキーカラーでコーデ・ネイル・ヘアアクセを提案する
/// - 不一致: ラッキーカラーはネイルや小物で少しだけ取り入れ、
///   主役は本人の得意な色に寄せる
List<SuggestionCard> todayRecommend(SuggestionContext context) {
  const ruleId = 'today_recommend';

  final personalColor = context.profile.personalColor;
  if (personalColor == null) {
    return const [
      SuggestionCard(
        ruleId: ruleId,
        title: '今日のおすすめ',
        body: 'パーソナルカラーを診断すると、今日のラッキーカラーと掛け合わせた提案が出ます。',
      ),
    ];
  }

  final myColors = context.masters.colorsForPersonalColor(personalColor);
  final luckyColor = context.masters.colorById(context.fortune.luckyColorId);

  SuggestionCard card({
    required ItemCategory category,
    required ColorItem? color,
    required String body,
  }) {
    return SuggestionCard(
      ruleId: ruleId,
      title: '今日の${category.label}',
      body: body,
      color: color,
      searchUrl: color == null
          ? null
          : RakutenSearch.searchUrl(
              colorName: color.name,
              categoryKeyword: category.searchKeyword,
            ),
      highlighted: category == context.fortune.luckyItemCategory,
    );
  }

  // ラッキーカラーが未知のIDだった場合は、色の掛け合わせを諦めて
  // 本人の得意な色だけで組む。配信データの不備でアプリを止めない。
  if (luckyColor == null) {
    return [
      for (final category in ItemCategory.values)
        card(
          category: category,
          color: _pickOwnColor(myColors, context.fortune.date, category),
          body: '${personalColor.label}が得意な色で、${category.label}をまとめてみる日。',
        ),
    ];
  }

  final isMyColor = myColors.any((color) => color.id == luckyColor.id);

  if (isMyColor) {
    return [
      for (final category in ItemCategory.values)
        card(
          category: category,
          color: luckyColor,
          body: '今日のラッキーカラーの${luckyColor.name}は、'
              '${personalColor.label}が得意な色。'
              '${category.label}に入れると今日の主役になれるはず。',
        ),
    ];
  }

  return [
    card(
      category: ItemCategory.nail,
      color: luckyColor,
      body: '今日のラッキーカラーは${luckyColor.name}。'
          '${personalColor.label}が得意な色ではないぶん、'
          'ネイルや小物でちょこっとだけ取り入れるとちょうどいいバランスに。',
    ),
    for (final category in const [ItemCategory.outfit, ItemCategory.hairAccessory])
      card(
        category: category,
        color: _pickOwnColor(myColors, context.fortune.date, category),
        body: '主役は得意な色で。${category.label}をこの色でまとめると、'
            'ラッキーカラーの差し色が効いてくる。',
      ),
  ];
}

/// 得意な色から1つ選ぶ。日付とカテゴリで変えて、毎日同じにならないようにする。
ColorItem? _pickOwnColor(
  List<ColorItem> colors,
  DateTime date,
  ItemCategory category,
) {
  if (colors.isEmpty) return null;
  final offset = date.day + category.index;
  return colors[offset % colors.length];
}
