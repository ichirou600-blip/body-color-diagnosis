import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

/// 広告ユニットIDと、広告を出すかどうかの設定。
///
/// **本番IDはリポジトリに書かない。**ビルド時に `--dart-define` で差し込む
/// （AdMob のアカウント作成前でもテストIDで動かせるようにするため）。
class AdConfig {
  const AdConfig({
    required this.enabled,
    required this.bannerUnitId,
    required this.nativeUnitId,
    required this.usingTestIds,
  });

  /// 広告を読み込まない設定。テストや、広告なしで動かしたいときの既定値。
  static const AdConfig disabled = AdConfig(
    enabled: false,
    bannerUnitId: '',
    nativeUnitId: '',
    usingTestIds: true,
  );

  final bool enabled;
  final String bannerUnitId;
  final String nativeUnitId;

  /// テストIDで動いているか。本番ビルドでこれが true なら差し込み漏れ。
  final bool usingTestIds;

  // Google 公式のデモ用ユニットID。実際の配信は行われず、クリックしても安全。
  // 出典: google_mobile_ads プラグインの example
  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const String testNativeIos = 'ca-app-pub-3940256099942544/3986624511';

  static const bool useProductionIds =
      bool.fromEnvironment('ADMOB_USE_PRODUCTION_IDS');
  static const String _prodBannerAndroid =
      String.fromEnvironment('ADMOB_BANNER_UNIT_ID_ANDROID');
  static const String _prodBannerIos =
      String.fromEnvironment('ADMOB_BANNER_UNIT_ID_IOS');
  static const String _prodNativeAndroid =
      String.fromEnvironment('ADMOB_NATIVE_UNIT_ID_ANDROID');
  static const String _prodNativeIos =
      String.fromEnvironment('ADMOB_NATIVE_UNIT_ID_IOS');

  /// 動作中のプラットフォームに合わせた設定を作る。
  ///
  /// 本番IDを使う指定なのにIDが渡されていない場合はテストIDに落とし、
  /// [usingTestIds] を true にする。空のユニットIDで読み込みに行っても
  /// 失敗するだけなので、テストIDで動くほうがまだ気づける。
  factory AdConfig.forCurrentPlatform() {
    final isAndroid = Platform.isAndroid;
    return AdConfig.resolve(
      useProductionIds: useProductionIds,
      productionBannerId: isAndroid ? _prodBannerAndroid : _prodBannerIos,
      productionNativeId: isAndroid ? _prodNativeAndroid : _prodNativeIos,
      testBannerId: isAndroid ? testBannerAndroid : testBannerIos,
      testNativeId: isAndroid ? testNativeAndroid : testNativeIos,
    );
  }

  /// プラットフォーム判定を切り離した本体。テストから直接呼べる。
  static AdConfig resolve({
    required bool useProductionIds,
    required String productionBannerId,
    required String productionNativeId,
    required String testBannerId,
    required String testNativeId,
  }) {
    final hasProductionIds =
        productionBannerId.isNotEmpty && productionNativeId.isNotEmpty;
    if (useProductionIds && hasProductionIds) {
      return AdConfig(
        enabled: true,
        bannerUnitId: productionBannerId,
        nativeUnitId: productionNativeId,
        usingTestIds: false,
      );
    }
    return AdConfig(
      enabled: true,
      bannerUnitId: testBannerId,
      nativeUnitId: testNativeId,
      usingTestIds: true,
    );
  }
}

/// 配下のウィジェットに [AdConfig] を渡す。
///
/// 置かれていない場合は [AdConfig.disabled] を返すので、
/// テストや広告なしの画面では広告ウィジェットが何も描かない。
class AdsScope extends InheritedWidget {
  const AdsScope({super.key, required this.config, required super.child});

  final AdConfig config;

  static AdConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdsScope>();
    return scope?.config ?? AdConfig.disabled;
  }

  @override
  bool updateShouldNotify(AdsScope oldWidget) => config != oldWidget.config;
}
