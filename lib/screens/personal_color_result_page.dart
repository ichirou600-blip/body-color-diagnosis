import 'package:flutter/material.dart';

import '../data/master_data.dart';
import '../models/enums.dart';

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
    this.onRetry,
  });

  final MasterData masters;
  final PersonalColorType type;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attribute = masters.personalColorAttributes[type];
    final colors = masters.colorsForPersonalColor(type);

    return Scaffold(
      appBar: AppBar(title: const Text('診断結果')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('あなたのパーソナルカラーは', style: theme.textTheme.bodyMedium),
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
                Text('似合う素材', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(attribute.materials.join('・')),
                const SizedBox(height: 24),
              ],
            ],
            if (colors.isNotEmpty) ...[
              Text('似合う色', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final color in colors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(color.argb),
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.dividerColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(color.name),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
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
