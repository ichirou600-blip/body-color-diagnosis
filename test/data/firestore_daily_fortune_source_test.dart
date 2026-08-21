import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/firestore_daily_fortune_source.dart';
import 'package:rakikara/models/daily_fortune.dart';
import 'package:rakikara/models/enums.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreDailyFortuneSource source;

  final date = DateTime(2026, 8, 21);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    source = FirestoreDailyFortuneSource(firestore);
  });

  Future<void> seed(
    Zodiac zodiac,
    Map<String, dynamic> data, {
    DateTime? on,
  }) {
    return firestore
        .collection(FirestoreDailyFortuneSource.collectionName)
        .doc(FirestoreDailyFortuneSource.documentIdFor(on ?? date))
        .collection(FirestoreDailyFortuneSource.zodiacSubcollectionName)
        .doc(zodiac.id)
        .set(data);
  }

  test('配信された占いを読める', () async {
    await seed(Zodiac.taurus, {
      'message': '今日はいい日になりそう。',
      'lucky_color_id': 'coral_pink',
      'lucky_item_category': 'nail',
    });

    final fortune = await source.fetch(zodiac: Zodiac.taurus, date: date);

    expect(fortune, isNotNull);
    expect(fortune!.message, '今日はいい日になりそう。');
    expect(fortune.luckyColorId, 'coral_pink');
    expect(fortune.luckyItemCategory, ItemCategory.nail);
    expect(fortune.zodiac, Zodiac.taurus);
    expect(fortune.date, date);
  });

  test('日付は YYYY-MM-DD でゼロ埋めされる', () {
    expect(
      FirestoreDailyFortuneSource.documentIdFor(DateTime(2026, 1, 5)),
      '2026-01-05',
    );
  });

  test('星座ごとに別のドキュメントを読む', () async {
    await seed(Zodiac.taurus, {
      'message': '牡牛座の運勢。',
      'lucky_color_id': 'coral_pink',
      'lucky_item_category': 'nail',
    });
    await seed(Zodiac.leo, {
      'message': '獅子座の運勢。',
      'lucky_color_id': 'royal_blue',
      'lucky_item_category': 'outfit',
    });

    expect((await source.fetch(zodiac: Zodiac.leo, date: date))!.message, '獅子座の運勢。');
    expect((await source.fetch(zodiac: Zodiac.taurus, date: date))!.message, '牡牛座の運勢。');
  });

  test('その日のぶんが無ければ null', () async {
    await seed(
      Zodiac.taurus,
      {
        'message': '昨日の運勢。',
        'lucky_color_id': 'coral_pink',
        'lucky_item_category': 'nail',
      },
      on: DateTime(2026, 8, 20),
    );

    expect(await source.fetch(zodiac: Zodiac.taurus, date: date), isNull);
  });

  group('配信データが壊れていても例外にせず null を返す', () {
    test('必須フィールドが欠けている', () async {
      await seed(Zodiac.taurus, {'message': '運勢文だけある。'});

      expect(await source.fetch(zodiac: Zodiac.taurus, date: date), isNull);
    });

    test('カテゴリが未知の値', () async {
      await seed(Zodiac.taurus, {
        'message': '運勢文。',
        'lucky_color_id': 'coral_pink',
        'lucky_item_category': 'unknown_category',
      });

      expect(await source.fetch(zodiac: Zodiac.taurus, date: date), isNull);
    });

    test('運勢文が空', () async {
      await seed(Zodiac.taurus, {
        'message': '',
        'lucky_color_id': 'coral_pink',
        'lucky_item_category': 'nail',
      });

      expect(await source.fetch(zodiac: Zodiac.taurus, date: date), isNull);
    });

    test('型が違う', () async {
      await seed(Zodiac.taurus, {
        'message': 123,
        'lucky_color_id': 'coral_pink',
        'lucky_item_category': 'nail',
      });

      expect(await source.fetch(zodiac: Zodiac.taurus, date: date), isNull);
    });
  });
}
