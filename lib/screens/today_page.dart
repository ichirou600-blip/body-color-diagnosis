import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';
import '../ads/native_ad_card.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/daily_fortune_source.dart';
import '../data/master_data.dart';
import '../logic/suggestion_engine.dart';
import '../models/daily_fortune.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_widgets.dart';

/// 今日の占いと、そこから作った提案カードを出す画面。
///
/// カードの中身は [SuggestionEngine] が決める。この画面は並べるだけ。
/// 掛け合わせを増やすときにここを触らずに済むようにしてある（`docs/SPEC.md` §6）。
class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.masters,
    required this.profile,
    required this.fortuneSource,
    this.engine = const SuggestionEngine(),
    this.today,
    this.openUrl,
  });

  final MasterData masters;
  final UserProfile profile;
  final DailyFortuneSource fortuneSource;
  final SuggestionEngine engine;

  /// テストから日付を固定するため。省略時は今日。
  final DateTime? today;

  /// テストから差し替えるため。省略時は端末のブラウザで開く。
  final Future<bool> Function(Uri url)? openUrl;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  DailyFortune? _fortune;
  List<SuggestionCard> _cards = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final zodiac = widget.profile.zodiac;
    if (zodiac == null) {
      setState(() {
        _loading = false;
        _fortune = null;
        _cards = const [];
      });
      return;
    }
    try {
      final fortune = await widget.fortuneSource.fetch(
        zodiac: zodiac,
        date: widget.today ?? DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _fortune = fortune;
        _cards = fortune == null
            ? const []
            : widget.engine.run(
                SuggestionContext(
                  profile: widget.profile,
                  fortune: fortune,
                  masters: widget.masters,
                ),
              );
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _open(Uri url) async {
    final messenger = ScaffoldMessenger.of(context);
    final opener = widget.openUrl ??
        (Uri target) => launchUrl(target, mode: LaunchMode.externalApplication);
    final opened = await opener(url);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('リンクを開けませんでした')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日のおすすめ')),
      bottomNavigationBar: const BannerAdSlot(),
      body: GradientBackground(child: SafeArea(child: _buildBody(context))),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Centered(
        children: [
          const Text('今日の占いを取れませんでした'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('再試行')),
        ],
      );
    }
    if (widget.profile.zodiac == null) {
      return const _Centered(
        children: [Text('誕生日を登録すると、今日の占いとおすすめが出ます。')],
      );
    }

    final fortune = _fortune;
    if (fortune == null) {
      return _Centered(
        children: [
          const Text('今日の占いはまだ配信されていません。'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('再読み込み')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.lavender, AppColors.blush],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.lavender.withValues(alpha: 0.32),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fortune.zodiac.label}の今日',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                fortune.message,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // docs/SPEC.md §8: 占いは娯楽目的である旨を必ず添える
        Text(
          '占いの内容は娯楽目的のものです。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 26),
        const SectionLabel('今日のおすすめ', color: AppColors.mint),
        const SizedBox(height: 12),
        for (final card in _cards) ...[
          _SuggestionTile(card: card, onOpen: _open),
          const SizedBox(height: 12),
        ],
        const NativeAdCard(),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SoftCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.card, required this.onOpen});

  final SuggestionCard card;
  final Future<void> Function(Uri url) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = card.color;
    final url = card.searchUrl;

    return SoftCard(
      color: card.highlighted ? AppColors.butterSoft : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (color != null) ...[
                ColorDot(argb: color.argb, size: 32),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(card.title, style: theme.textTheme.titleMedium),
              ),
              if (card.highlighted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.butter,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '今日の推し',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(card.body, style: theme.textTheme.bodyMedium),
          if (url != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => onOpen(url),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('楽天でさがす'),
            ),
          ],
        ],
      ),
    );
  }
}
