import 'package:flutter/material.dart';

import '../data/master_data.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';

/// シェア画像として書き出す結果カード。
///
/// 画面に出しているものをそのまま画像化するので、レイアウトは1つしか持たない。
/// 書き出しサイズは [ShareCard.width] × [ShareCard.height] に固定してある
/// （SNSに載せやすい 4:5）。実際の解像度は書き出し時の pixelRatio で稼ぐ。
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.masters,
    required this.profile,
  });

  /// 論理サイズ。書き出し時に pixelRatio を掛けた実サイズになる。
  static const double width = 360;
  static const double height = 450;

  final MasterData masters;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final pc = profile.personalColor;
    final kokkaku = profile.kokkaku;
    final colors = pc == null ? const [] : masters.colorsForPersonalColor(pc);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.blush, AppColors.lavender],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ラキカラ',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 3,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'わたしのタイプ',
                style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 12),
              _Line(label: 'パーソナルカラー', value: pc?.label),
              const SizedBox(height: 10),
              _Line(label: '骨格', value: kokkaku?.label),
              const SizedBox(height: 10),
              _Line(label: '星座', value: profile.zodiac?.label),
              const Spacer(),
              if (colors.isNotEmpty) ...[
                const Text(
                  '似合う色',
                  style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 全色は入りきらないので先頭から詰める。
                    for (final color in colors.take(12))
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Color(color.argb),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                '#ラキカラ',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 116,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ),
        Expanded(
          child: Text(
            value ?? '未診断',
            style: TextStyle(
              fontSize: value == null ? 16 : 22,
              fontWeight: FontWeight.w700,
              color: value == null ? AppColors.inkMuted : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
