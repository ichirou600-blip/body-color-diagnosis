import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';
import '../ads/native_ad_card.dart';

import '../data/master_data.dart';
import '../models/enums.dart';
import 'style_match_card.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_widgets.dart';

/// 骨格診断の結果画面。
///
/// 表示するテキストは `type_attributes.json` / `pc_x_kokkaku.json` の内容をそのまま出す。
/// 体型への言及を避ける文言ルールはコンテンツ側で担保する（`docs/SPEC.md` §8）。
class KokkakuResultPage extends StatelessWidget {
  const KokkakuResultPage({
    super.key,
    required this.masters,
    required this.type,
    required this.personalColor,
    this.onRetry,
  });

  final MasterData masters;
  final KokkakuType type;

  /// 判明していれば PC×骨格 のテキストも一緒に出す。
  final PersonalColorType? personalColor;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attribute = masters.kokkakuAttributes[type];

    return Scaffold(
      appBar: AppBar(title: const Text('診断結果')),
      bottomNavigationBar: const BannerAdSlot(),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              HeroBadge(
                label: 'あなたの骨格タイプは',
                value: type.label,
                colors: const [AppColors.lavender, AppColors.mint],
              ),
              const SizedBox(height: 20),
              if (attribute != null) ...[
                SoftCard(
                  child: Text(
                    attribute.description,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                if (attribute.keywords.isNotEmpty) ...[
                  const SectionLabel('キーワード', color: AppColors.lavender),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < attribute.keywords.length; i++)
                        Chip(
                          label: Text(attribute.keywords[i]),
                          backgroundColor: AppColors
                              .accentsSoft[i % AppColors.accentsSoft.length],
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (attribute.materials.isNotEmpty) ...[
                  const SectionLabel('得意な素材', color: AppColors.mint),
                  const SizedBox(height: 10),
                  SoftCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      attribute.materials.join('・'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
              StyleMatchCard(
                masters: masters,
                personalColor: personalColor,
                kokkaku: type,
              ),
              const NativeAdCard(),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ホームに戻る'),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry!();
                  },
                  child: const Text('もう一度診断する'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
