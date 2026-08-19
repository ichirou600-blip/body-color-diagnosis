import 'package:flutter/material.dart';

void main() {
  runApp(const RakikaraApp());
}

/// ラキカラのルートウィジェット。
///
/// Step 0 時点ではビルド・配信パイプラインを貫通させるための雛形。
/// 画面の中身は Step 1 以降で `docs/SPEC.md` §9 に沿って差し替える。
class RakikaraApp extends StatelessWidget {
  const RakikaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ラキカラ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF48FB1)),
        useMaterial3: true,
      ),
      home: const PlaceholderHomePage(),
    );
  }
}

class PlaceholderHomePage extends StatelessWidget {
  const PlaceholderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ラキカラ', style: theme.textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              'パーソナルカラー診断＆毎日占い',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Text(
              'Step 0: ビルド確認用の雛形です',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
