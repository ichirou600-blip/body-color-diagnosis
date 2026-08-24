import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';
import '../ads/native_ad_card.dart';

import '../data/master_data.dart';
import '../models/enums.dart';
import 'style_match_card.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_widgets.dart';

/// パーソナルカラー診断の結果画面。
///
/// 表示するテキストは `type_attributes.json` の内容をそのまま出す。
/// 文言のルール（似合うものの提案だけを書く）はコンテンツ側で担保する
/// （`docs/SPEC.md` §8）。
class PersonalColorResultPage extends StatelessWidget {
  const PersonalColorResultPage({
    super.key,
    required this.masters,
    required this.type,
    required this.kokkaku,
    this.onRetry,
  });

  final MasterData masters;
  final PersonalColorType type;

  /// 判明していれば PC×骨格 のテキストも一緒に出す。
  final KokkakuType? kokkaku;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attribute = masters.personalColorAttributes[type];
    final colors = masters.colorsForPersonalColor(type);

    return Scaffold(
      appBar: AppBar(title: const Text('診断結果')),
      bottomNavigationBar: const BannerAdSlot(),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              HeroBadge(
                label: 'あなたのパーソナルカラーは',
                value: type.label,
                colors: const [AppColors.blush, AppColors.lavender],
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
                  const SectionLabel('キーワード'),
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
                  const SectionLabel('似合う素材', color: AppColors.lavender),
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
              if (colors.isNotEmpty) ...[
                const SectionLabel('似合う色', color: AppColors.mint),
                const SizedBox(height: 10),
                SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final color in colors)
                        SizedBox(
                          width: 66,
                          child: Column(
                            children: [
                              ColorDot(argb: color.argb, size: 40),
                              const SizedBox(height: 6),
                              Text(
                                color.name,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              StyleMatchCard(
                masters: masters,
                personalColor: type,
                kokkaku: kokkaku,
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
