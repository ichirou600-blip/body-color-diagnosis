import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_links.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_widgets.dart';

/// このアプリについて。
///
/// ストア審査で求められるもの（プライバシーポリシーへの導線、
/// 占いが娯楽目的である旨）と、同梱フォントのライセンス表示をまとめる。
class AboutPage extends StatelessWidget {
  const AboutPage({
    super.key,
    required this.version,
    this.openUrl,
  });

  /// 表示するバージョン。取得できなければ null。
  final String? version;

  /// テストから差し替えるため。省略時は端末のブラウザで開く。
  final Future<bool> Function(Uri url)? openUrl;

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opener = openUrl ??
        (Uri target) => launchUrl(target, mode: LaunchMode.externalApplication);
    final opened = await opener(Uri.parse(AppLinks.privacyPolicy));
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('リンクを開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('このアプリについて')),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ラキカラ', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      version == null ? 'バージョン —' : 'バージョン $version',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('たいせつなこと'),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // docs/SPEC.md §8: 占いは娯楽目的である旨をアプリ内に注記する
                    Text(
                      '占いの内容は娯楽目的のものです。'
                      '結果を進路や健康の判断に使わないでください。',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    // docs/SPEC.md §8: 体型のネガティブ言及をしない方針を明示する
                    Text(
                      '診断は「似合うものを見つける」ためのものです。'
                      '体型や見た目の良し悪しを決めるものではありません。',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '誕生日や診断結果はこの端末の中だけに保存され、'
                      'どこにも送信されません。',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('リンク', color: AppColors.lavender),
              const SizedBox(height: 12),
              SoftCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('プライバシーポリシー'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _openPrivacyPolicy(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('ライセンス'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'ラキカラ',
                        applicationVersion: version,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
