import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/models/enums.dart';

void main() {
  group('Zodiac.fromDate', () {
    test('各星座の開始日と終了日が正しく判定される', () {
      for (final zodiac in Zodiac.values) {
        // 山羊座のように年をまたぐ場合、終了日は翌年側になる
        final startYear = 2024;
        final endYear = zodiac.fromMonth <= zodiac.toMonth ? 2024 : 2025;
        expect(
          Zodiac.fromDate(DateTime(startYear, zodiac.fromMonth, zodiac.fromDay)),
          zodiac,
          reason: '${zodiac.label} の開始日',
        );
        expect(
          Zodiac.fromDate(DateTime(endYear, zodiac.toMonth, zodiac.toDay)),
          zodiac,
          reason: '${zodiac.label} の終了日',
        );
      }
    });

    test('1年365日すべてがいずれかの星座に割り当てられる', () {
      var date = DateTime(2023, 1, 1);
      final last = DateTime(2023, 12, 31);
      var days = 0;
      while (!date.isAfter(last)) {
        expect(() => Zodiac.fromDate(date), returnsNormally, reason: '$date');
        date = date.add(const Duration(days: 1));
        days++;
      }
      expect(days, 365);
    });

    test('年をまたぐ山羊座が前後どちらの年でも判定される', () {
      expect(Zodiac.fromDate(DateTime(2024, 12, 25)), Zodiac.capricorn);
      expect(Zodiac.fromDate(DateTime(2025, 1, 5)), Zodiac.capricorn);
      expect(Zodiac.fromDate(DateTime(2025, 1, 20)), Zodiac.aquarius);
    });

    test('うるう日も判定できる', () {
      expect(Zodiac.fromDate(DateTime(2024, 2, 29)), Zodiac.pisces);
    });
  });

  group('tryFromId', () {
    test('既知のIDを解決し、未知のIDでは null を返す', () {
      expect(PersonalColorType.tryFromId('spring'), PersonalColorType.spring);
      expect(PersonalColorType.tryFromId('spring2'), isNull);
      expect(PersonalColorType.tryFromId(null), isNull);
      expect(KokkakuType.tryFromId('wave'), KokkakuType.wave);
      expect(KokkakuType.tryFromId(''), isNull);
      expect(Zodiac.tryFromId('leo'), Zodiac.leo);
    });
  });
}
