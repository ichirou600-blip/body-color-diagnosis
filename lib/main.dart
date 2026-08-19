import 'package:flutter/material.dart';

import 'data/master_data.dart';
import 'data/master_repository.dart';
import 'data/profile_repository.dart';
import 'models/user_profile.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const RakikaraApp());
}

/// ラキカラのルートウィジェット。
class RakikaraApp extends StatelessWidget {
  const RakikaraApp({
    super.key,
    this.masterRepository = const MasterRepository(),
    this.profileRepository = const ProfileRepository(),
  });

  final MasterRepository masterRepository;
  final ProfileRepository profileRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ラキカラ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF48FB1)),
        useMaterial3: true,
      ),
      home: AppRoot(
        masterRepository: masterRepository,
        profileRepository: profileRepository,
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
  });

  final MasterRepository masterRepository;
  final ProfileRepository profileRepository;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  MasterData? _masters;
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
      if (!mounted) return;
      setState(() {
        _masters = masters;
        _profile = profile;
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

  Future<void> _saveProfile(UserProfile profile) async {
    await widget.profileRepository.save(profile);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final error = _error;
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('マスタの読み込みに失敗しました'),
                const SizedBox(height: 12),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(onPressed: _load, child: const Text('再試行')),
              ],
            ),
          ),
        ),
      );
    }

    return HomePage(
      masters: _masters!,
      profile: _profile,
      onProfileChanged: _saveProfile,
    );
  }
}
