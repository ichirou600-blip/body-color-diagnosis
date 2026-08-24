import 'package:flutter/material.dart';

import 'ads/ad_config.dart';
import 'ads/ads_bootstrap.dart';
import 'data/daily_fortune_source.dart';
import 'data/fortune_source_factory.dart';
import 'data/master_data.dart';
import 'data/master_repository.dart';
import 'data/profile_repository.dart';
import 'models/user_profile.dart';
import 'screens/home_page.dart';
import 'theme/app_theme.dart';
import 'widgets/soft_widgets.dart';

void main() {
  runApp(const RakikaraApp());
}

/// ラキカラのルートウィジェット。
class RakikaraApp extends StatelessWidget {
  const RakikaraApp({
    super.key,
    this.masterRepository = const MasterRepository(),
    this.profileRepository = const ProfileRepository(),
    this.fortuneSource,
    this.adConfig,
  });

  final MasterRepository masterRepository;
  final ProfileRepository profileRepository;

  /// 省略時は Firebase の初期化を試み、できなければ端末内の仮データに落ちる。
  final DailyFortuneSource? fortuneSource;

  /// 省略時は広告SDKを初期化する。テストでは [AdConfig.disabled] を渡す。
  final AdConfig? adConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ラキカラ',
      theme: buildAppTheme(),
      home: AppRoot(
        masterRepository: masterRepository,
        profileRepository: profileRepository,
        fortuneSource: fortuneSource,
        adConfig: adConfig,
      ),
    );
  }
}

/// マスタとプロフィールを読み込み、読み終わったらホームを出す。
///
/// 状態管理は Step 2 時点では setState で足りている。画面が増えて
/// 持ち回りがつらくなったら、その時点で導入を検討する。
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.masterRepository,
    required this.profileRepository,
    this.fortuneSource,
    this.adConfig,
  });

  final MasterRepository masterRepository;
  final ProfileRepository profileRepository;
  final DailyFortuneSource? fortuneSource;
  final AdConfig? adConfig;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  MasterData? _masters;
  DailyFortuneSource _fortuneSource = const LocalDailyFortuneSource();
  AdConfig _adConfig = AdConfig.disabled;
  UserProfile _profile = const UserProfile();
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final masters = await widget.masterRepository.load();
      final profile = await widget.profileRepository.load();
      final fortuneSource =
          widget.fortuneSource ?? await createDailyFortuneSource();
      final adConfig = widget.adConfig ?? await initializeAds();
      if (!mounted) return;
      setState(() {
        _masters = masters;
        _profile = profile;
        _fortuneSource = fortuneSource;
        _adConfig = adConfig;
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

  /// 常に最新のプロフィールに対して更新をかける。
  ///
  /// 画面側が保持している（＝古くなっているかもしれない）プロフィールを
  /// 丸ごと渡させると、あとから来た診断結果が前の結果を消してしまう。
  Future<void> _updateProfile(UserProfile Function(UserProfile current) update) async {
    final next = update(_profile);
    await widget.profileRepository.save(next);
    if (!mounted) return;
    setState(() => _profile = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: GradientBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final error = _error;
    if (error != null) {
      return Scaffold(
        body: GradientBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'マスタの読み込みに失敗しました',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(onPressed: _load, child: const Text('再試行')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 配下の画面はここから広告設定を受け取る。
    return AdsScope(
      config: _adConfig,
      child: HomePage(
        masters: _masters!,
        profile: _profile,
        onProfileChanged: _updateProfile,
        fortuneSource: _fortuneSource,
      ),
    );
  }
}
