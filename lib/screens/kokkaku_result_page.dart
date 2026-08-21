import 'package:flutter/material.dart';

import '../data/master_data.dart';
import '../models/enums.dart';
import 'style_match_card.dart';

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('あなたの骨格タイプは', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(type.label, style: theme.textTheme.displaySmall),
            const SizedBox(height: 24),
            if (attribute != null) ...[
              Text(attribute.description, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              if (attribute.keywords.isNotEmpty) ...[
                Text('キーワード', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final keyword in attribute.keywords) Chip(label: Text(keyword)),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              if (attribute.materials.isNotEmpty) ...[
                Text('得意な素材', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(attribute.materials.join('・')),
                const SizedBox(height: 24),
              ],
            ],
            StyleMatchCard(
              masters: masters,
              personalColor: personalColor,
              kokkaku: type,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ホームに戻る'),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
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
    );
  }
}
