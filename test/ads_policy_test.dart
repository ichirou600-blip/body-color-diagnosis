import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/ads/ads_bootstrap.dart';

/// 広告まわりの方針を機械的に見張る。
///
/// `CLAUDE.md` の「絶対に破らないルール」3 と `docs/SPEC.md` §2。
/// レビューで気をつけるだけだと、あとから1行足されて崩れる種類の約束なので
/// テストで固定する。
void main() {
  test('広告リクエストは非パーソナライズを既定にしている', () {
    expect(kAdRequest.nonPersonalizedAds, isTrue);
  });

  test('未成年向けの配慮設定を入れている', () {
    final source = File('lib/ads/ads_bootstrap.dart').readAsStringSync();

    // TFUA に相当する現行の指定
    expect(source, contains('AgeRestrictedTreatment.teen'));
    expect(source, contains('maxAdContentRating'));
  });

  test('ATT（トラッキング許可）を求めていない', () {
    // 利用目的の文言が Info.plist にあると、iOS はプロンプトを出せてしまう。
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(
      plist,
      isNot(contains('NSUserTrackingUsageDescription')),
      reason: 'ATT プロンプトは出さない方針（docs/SPEC.md §2）',
    );

    // コード側でも ATT を呼んでいないこと
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('requestTrackingAuthorization')),
        reason: file.path,
      );
      expect(
        source,
        isNot(contains('AppTrackingTransparency')),
        reason: file.path,
      );
    }
  });

  test('AdMob のアプリIDが iOS / Android 双方に設定されている', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(plist, contains('GADApplicationIdentifier'));
    expect(manifest, contains('com.google.android.gms.ads.APPLICATION_ID'));
  });

  test('リワード広告はまだ入れていない（P1）', () {
    // docs/SPEC.md §4: リワードは P1。先回りで入れない
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      expect(
        file.readAsStringSync(),
        isNot(contains('RewardedAd')),
        reason: file.path,
      );
    }
  });
}
