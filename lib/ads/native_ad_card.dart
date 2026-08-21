import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ads_bootstrap.dart';

/// 診断結果・おすすめ画面に差し込むネイティブ広告（`docs/SPEC.md` §2）。
///
/// プラグイン同梱のテンプレートを使うので、iOS / Android 側に
/// ネイティブ広告用のファクトリを書く必要がない。
///
/// 広告が無効・未読み込み・読み込み失敗のいずれでも何も描かない。
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({super.key});

  /// medium テンプレートの表示高さ。
  static const double height = 330;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    final config = AdsScope.of(context);
    if (!config.enabled) return;
    _requested = true;
    _load(config);
  }

  void _load(AdConfig config) {
    final ad = NativeAd(
      adUnitId: config.nativeUnitId,
      request: kAdRequest,
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.medium),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: NativeAdCard.height,
        child: AdWidget(ad: ad),
      ),
    );
  }
}
