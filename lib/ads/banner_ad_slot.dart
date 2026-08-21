import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ads_bootstrap.dart';

/// 画面下部に常設するバナー広告（`docs/SPEC.md` §2）。
///
/// 広告が無効・未読み込み・読み込み失敗のいずれでも、高さ0で何も描かない。
/// 「広告の枠だけ空いている」状態を作らないため。
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面幅が要るので initState ではなくここで読み込む。
    if (_requested) return;
    final config = AdsScope.of(context);
    if (!config.enabled) return;
    _requested = true;
    _load(config);
  }

  Future<void> _load(AdConfig config) async {
    // アダプティブバナーは端末幅に合わせた高さになり、固定サイズより収益がよい。
    // 取得できなければ標準の 320x50 に落とす。
    final width = MediaQuery.of(context).size.width.truncate();
    final adaptiveSize =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    final ad = BannerAd(
      adUnitId: config.bannerUnitId,
      size: adaptiveSize ?? AdSize.banner,
      request: kAdRequest,
      listener: BannerAdListener(
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
    await ad.load();
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
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
