/// マスタJSON・保存データで使うID語彙。
///
/// ここの `id` 文字列は `assets/*.json` と `shared_preferences` の
/// 保存値の両方に現れる。**変更すると保存済みプロフィールが読めなくなる**ため、
/// `docs/DATA_SCHEMA.md` の取り決めどおりに固定する。
library;

/// パーソナルカラー4分類。
enum PersonalColorType {
  spring('spring', 'イエベ春'),
  summer('summer', 'ブルベ夏'),
  autumn('autumn', 'イエベ秋'),
  winter('winter', 'ブルベ冬');

  const PersonalColorType(this.id, this.label);

  final String id;
  final String label;

  static PersonalColorType? tryFromId(String? id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// 骨格3分類。
enum KokkakuType {
  straight('straight', 'ストレート'),
  wave('wave', 'ウェーブ'),
  natural('natural', 'ナチュラル');

  const KokkakuType(this.id, this.label);

  final String id;
  final String label;

  static KokkakuType? tryFromId(String? id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// 星座12種。`from` / `to` は誕生日から星座を求めるための境界（月, 日）。
enum Zodiac {
  aries('aries', '牡羊座', 3, 21, 4, 19),
  taurus('taurus', '牡牛座', 4, 20, 5, 20),
  gemini('gemini', '双子座', 5, 21, 6, 21),
  cancer('cancer', '蟹座', 6, 22, 7, 22),
  leo('leo', '獅子座', 7, 23, 8, 22),
  virgo('virgo', '乙女座', 8, 23, 9, 22),
  libra('libra', '天秤座', 9, 23, 10, 23),
  scorpio('scorpio', '蠍座', 10, 24, 11, 22),
  sagittarius('sagittarius', '射手座', 11, 23, 12, 21),
  capricorn('capricorn', '山羊座', 12, 22, 1, 19),
  aquarius('aquarius', '水瓶座', 1, 20, 2, 18),
  pisces('pisces', '魚座', 2, 19, 3, 20);

  const Zodiac(
    this.id,
    this.label,
    this.fromMonth,
    this.fromDay,
    this.toMonth,
    this.toDay,
  );

  final String id;
  final String label;
  final int fromMonth;
  final int fromDay;
  final int toMonth;
  final int toDay;

  static Zodiac? tryFromId(String? id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }

  /// 誕生日から星座を求める。年をまたぐ山羊座も扱える。
  ///
  /// 娯楽目的のアプリなので、年ごとに数時間ずれる正確な太陽黄経ではなく、
  /// 一般的に使われる固定の日付境界を使う。
  static Zodiac fromDate(DateTime date) {
    for (final value in values) {
      final startsBeforeYearEnd = value.fromMonth <= value.toMonth;
      final afterStart = date.month == value.fromMonth && date.day >= value.fromDay;
      final beforeEnd = date.month == value.toMonth && date.day <= value.toDay;
      if (startsBeforeYearEnd) {
        final inBetween = date.month > value.fromMonth && date.month < value.toMonth;
        if (afterStart || beforeEnd || inBetween) return value;
      } else {
        // 山羊座（12/22〜1/19）だけ年をまたぐ
        if (afterStart || beforeEnd) return value;
      }
    }
    // 上の範囲で12星座すべての日付を覆っているのでここには来ない
    throw ArgumentError('星座を判定できませんでした: $date');
  }
}
