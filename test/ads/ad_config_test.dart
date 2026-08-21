import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/ads/ad_config.dart';
import 'package:rakikara/ads/banner_ad_slot.dart';
import 'package:rakikara/ads/native_ad_card.dart';

void main() {
  group('AdConfig.resolve', () {
    AdConfig resolve({
      required bool useProductionIds,
      String banner = 'prod-banner',
      String native = 'prod-native',
    }) {
      return AdConfig.resolve(
        useProductionIds: useProductionIds,
        productionBannerId: banner,
        productionNativeId: native,
        testBannerId: 'test-banner',
        testNativeId: 'test-native',
      );
    }

    test('本番指定でIDが揃っていれば本番IDを使う', () {
      final config = resolve(useProductionIds: true);

      expect(config.bannerUnitId, 'prod-banner');
      expect(config.nativeUnitId, 'prod-native');
      expect(config.usingTestIds, isFalse);
      expect(config.enabled, isTrue);
    });

    test('本番指定でなければテストIDを使う', () {
      final config = resolve(useProductionIds: false);

      expect(config.bannerUnitId, 'test-banner');
      expect(config.usingTestIds, isTrue);
    });

    test('本番指定でもIDが渡っていなければテストIDに落ちる', () {
      // --dart-define の差し込み漏れ。空のユニットIDで読みに行くより、
      // テストIDで動いて usingTestIds から気づけるほうがよい。
      final config = resolve(useProductionIds: true, banner: '');

      expect(config.bannerUnitId, 'test-banner');
      expect(config.nativeUnitId, 'test-native');
      expect(config.usingTestIds, isTrue);
    });

    test('片方だけ本番IDがある中途半端な状態でもテストIDに落ちる', () {
      final config = resolve(useProductionIds: true, native: '');

      expect(config.usingTestIds, isTrue);
      expect(config.bannerUnitId, 'test-banner');
    });
  });

  group('テスト用ユニットIDはGoogle公式のデモ用IDである', () {
    test('すべて公式のパブリッシャIDに属する', () {
      const officialPublisher = 'ca-app-pub-3940256099942544/';

      for (final id in [
        AdConfig.testBannerAndroid,
        AdConfig.testBannerIos,
        AdConfig.testNativeAndroid,
        AdConfig.testNativeIos,
      ]) {
        expect(id, startsWith(officialPublisher));
      }
    });

    test('プラットフォームごとに別のIDを使う', () {
      expect(AdConfig.testBannerAndroid, isNot(AdConfig.testBannerIos));
      expect(AdConfig.testNativeAndroid, isNot(AdConfig.testNativeIos));
    });
  });

  group('AdsScope', () {
    testWidgets('置かれていなければ広告は無効', (tester) async {
      late AdConfig seen;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              seen = AdsScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(seen.enabled, isFalse);
    });

    testWidgets('広告が無効なら、広告ウィジェットは何も描かない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(children: [NativeAdCard(), BannerAdSlot()]),
          ),
        ),
      );
      await tester.pump();

      // 高さ0で存在するだけ。枠が空くことはない
      expect(tester.getSize(find.byType(NativeAdCard)).height, 0);
      expect(tester.getSize(find.byType(BannerAdSlot)).height, 0);
    });
  });
}
