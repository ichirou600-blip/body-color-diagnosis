import 'package:flutter/material.dart';

import '../data/master_data.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';

/// PC×骨格の掛け合わせテキストを出すカード。
///
/// 両方の診断が終わっていないときは、何を診断すれば見られるかを出す。
/// ホームと各結果画面で共用する。
class StyleMatchCard extends StatelessWidget {
  const StyleMatchCard({
    super.key,
    required this.masters,
    required this.personalColor,
    required this.kokkaku,
  });

  final MasterData masters;
  final PersonalColorType? personalColor;
  final KokkakuType? kokkaku;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pc = personalColor;
    final kk = kokkaku;

    final String body;
    if (pc == null && kk == null) {
      body = 'パーソナルカラーと骨格の両方を診断すると、あなたに似合うスタイルが出ます。';
    } else if (pc == null) {
      body = 'パーソナルカラーも診断すると、あなたに似合うスタイルが出ます。';
    } else if (kk == null) {
      body = '骨格も診断すると、あなたに似合うスタイルが出ます。';
    } else {
      // 12通りすべてが揃っていれば必ず引ける。仮データで欠けている間だけ null になる。
      body = masters.styleTextFor(pc, kk) ?? 'このタイプの組み合わせのテキストはまだ準備中です。';
    }

    final heading = pc != null && kk != null
        ? '${pc.label} × ${kk.label} に似合うスタイル'
        : '似合うスタイル';

    final ready = pc != null && kk != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ready
              ? [AppColors.blushSoft, AppColors.lavenderSoft]
              : [Colors.white, AppColors.line.withValues(alpha: 0.5)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ready ? '💫' : '🔒', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(heading, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
