import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daily_fortune.dart';
import '../models/enums.dart';
import 'daily_fortune_source.dart';

/// Firestore から配信された占いを読む。
///
/// 読み取り専用。**このアプリが Firestore に書き込むことはない**
/// （書き込みは Cloud Functions のみ。`firestore.rules` でも禁じている）。
///
/// 保存先は `daily_fortune/{YYYY-MM-DD}/zodiacs/{zodiacId}`。
/// `docs/SPEC.md` §5 の `daily_fortune/{date}/{zodiac}` を、コレクションと
/// ドキュメントが交互でなければならない Firestore のパス規則に合わせた形。
class FirestoreDailyFortuneSource implements DailyFortuneSource {
  const FirestoreDailyFortuneSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String collectionName = 'daily_fortune';
  static const String zodiacSubcollectionName = 'zodiacs';

  /// Firestore のドキュメントIDに使う日付表記。Cloud Functions 側と揃える。
  static String documentIdFor(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Future<DailyFortune?> fetch({
    required Zodiac zodiac,
    required DateTime date,
  }) async {
    final snapshot = await _firestore
        .collection(collectionName)
        .doc(documentIdFor(date))
        .collection(zodiacSubcollectionName)
        .doc(zodiac.id)
        .get();

    final data = snapshot.data();
    if (data == null) return null;
    return _parse(data, zodiac: zodiac, date: date);
  }

  /// 配信データが想定と違っても例外にせず null を返す。
  ///
  /// 生成側の不備でアプリが使えなくなるより、「今日はまだ配信されていません」と
  /// 出るほうがまし。呼び出し側はどちらも同じ扱いでよい。
  static DailyFortune? _parse(
    Map<String, dynamic> data, {
    required Zodiac zodiac,
    required DateTime date,
  }) {
    final message = data['message'];
    final colorId = data['lucky_color_id'];
    final category = ItemCategory.tryFromId(data['lucky_item_category'] as String?);

    if (message is! String || message.isEmpty) return null;
    if (colorId is! String || colorId.isEmpty) return null;
    if (category == null) return null;

    return DailyFortune(
      date: DateTime(date.year, date.month, date.day),
      zodiac: zodiac,
      message: message,
      luckyColorId: colorId,
      luckyItemCategory: category,
    );
  }
}
