import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// 広告のリクエスト設定。**すべての広告リクエストでこれを使う。**
///
/// `nonPersonalizedAds: true` が要点。主対象が未成年なので
/// 非パーソナライズ広告を既定にする（`docs/SPEC.md` §2 /
/// `CLAUDE.md` の「絶対に破らないルール」3）。
const AdRequest kAdRequest = AdRequest(nonPersonalizedAds: true);

/// 広告SDKを初期化する。
///
/// **ATT（トラッキング許可）のプロンプトは出さない。**
/// 非パーソナライズ広告しか出さないので許可を求める必要がなく、
/// 未成年向けアプリで許可ダイアログを増やさない方針（`docs/SPEC.md` §2）。
///
/// 初期化に失敗しても例外を投げない。広告が出ないだけで、
/// 診断や占いは動かせるほうがよい。
Future<AdConfig> initializeAds() async {
  try {
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        // 13〜18歳が主対象。TFUA に相当する現行の指定。
        ageRestrictedTreatment: AgeRestrictedTreatment.teen,
        // 対象年齢に合わせて広告の内容も絞る。
        maxAdContentRating: MaxAdContentRating.t,
      ),
    );
    final config = AdConfig.forCurrentPlatform();
    if (config.usingTestIds && AdConfig.useProductionIds) {
      // リリースビルドでここに来たら、--dart-define の差し込み漏れ
      debugPrint('本番の広告ユニットIDが渡されていないため、テストIDで動作します');
    }
    return config;
  } catch (error) {
    debugPrint('広告SDKを初期化できなかったため、広告なしで動作します: $error');
    return AdConfig.disabled;
  }
}
