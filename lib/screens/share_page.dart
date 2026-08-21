import 'package:flutter/material.dart';

import '../data/master_data.dart';
import '../logic/share_image.dart';
import '../models/user_profile.dart';
import 'share_card.dart';

/// シェア画像のプレビューと共有。
///
/// 画面に出しているカードをそのまま画像化するので、
/// 「見えているもの」と「送られるもの」がずれない。
class SharePage extends StatefulWidget {
  const SharePage({
    super.key,
    required this.masters,
    required this.profile,
    this.shareService = const ShareImageService(),
  });

  final MasterData masters;
  final UserProfile profile;
  final ShareImageService shareService;

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return; // 連打で共有シートが多重に開くのを防ぐ
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await widget.shareService.capture(_cardKey);
      await widget.shareService.share(
        bytes,
        text: 'わたしのタイプ診断してみた #ラキカラ',
        origin: _shareButtonRect(),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('シェア画像を作れませんでした: $error')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// iPad ではここを基点に共有シートがポップオーバーで開く。
  /// 取れなければ null を返し、iPhone / Android ではそのままで問題ない。
  Rect? _shareButtonRect() {
    final object = _shareButtonKey.currentContext?.findRenderObject();
    if (object is! RenderBox || !object.hasSize) return null;
    return object.localToGlobal(Offset.zero) & object.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('シェア')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: ShareCard(
                  masters: widget.masters,
                  profile: widget.profile,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: _shareButtonKey,
              onPressed: _sharing ? null : _share,
              icon: const Icon(Icons.ios_share),
              label: Text(_sharing ? '準備中…' : 'この画像をシェアする'),
            ),
            const SizedBox(height: 12),
            Text(
              '共有シートから「画像を保存」を選ぶと、端末のアルバムに保存できます。',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
