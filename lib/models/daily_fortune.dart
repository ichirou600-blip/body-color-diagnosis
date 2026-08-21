import 'enums.dart';

/// 提案するアイテムのカテゴリ。
///
/// Cloud Functions の生成プロンプトでもこの `id` から選ばせる
/// （自由生成させると検索リンクが作れなくなるため。`docs/SPEC.md` §7）。
enum ItemCategory {
  outfit('outfit', 'コーデ', 'トップス'),
  nail('nail', 'ネイル', 'ネイルシール'),
  hairAccessory('hair_accessory', 'ヘアアクセ', 'ヘアアクセサリー');

  const ItemCategory(this.id, this.label, this.searchKeyword);

  final String id;

  /// 画面に出す名前。
  final String label;

  /// 楽天検索に投げる語。`label` のままだと検索がヒットしにくいので分けてある。
  final String searchKeyword;

  static ItemCategory? tryFromId(String? id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// その日の占い。Step 6 で Firestore から配信する。
///
/// ユーザー個人の情報は含まない。星座単位の共有データなので、
/// 誰が読んだかをサーバーが知ることはない（`docs/SPEC.md` §5）。
class DailyFortune {
  const DailyFortune({
    required this.date,
    required this.zodiac,
    required this.message,
    required this.luckyColorId,
    required this.luckyItemCategory,
  });

  final DateTime date;
  final Zodiac zodiac;

  /// 運勢文。娯楽目的である旨の注記を必ず添えて表示する（`docs/SPEC.md` §8）。
  final String message;

  /// `color_master.json` の色ID。
  final String luckyColorId;

  final ItemCategory luckyItemCategory;
}
