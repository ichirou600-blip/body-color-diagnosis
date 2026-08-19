import 'package:flutter/material.dart';

import 'data/master_data.dart';
import 'data/master_repository.dart';
import 'data/profile_repository.dart';
import 'models/enums.dart';
import 'models/user_profile.dart';

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
      home: DataStatusPage(
        masterRepository: masterRepository,
        profileRepository: profileRepository,
      ),
    );
  }
}

/// Step 1 の完了確認用の画面。
///
/// マスタが読めていること・プロフィールが再起動後も残ることを実機で見るためだけの
/// 暫定画面。Step 2 以降で診断フローの画面に置き換える（`docs/SPEC.md` §9）。
class DataStatusPage extends StatefulWidget {
  const DataStatusPage({
    super.key,
    required this.masterRepository,
    required this.profileRepository,
  });

  final MasterRepository masterRepository;
  final ProfileRepository profileRepository;

  @override
  State<DataStatusPage> createState() => _DataStatusPageState();
}

class _DataStatusPageState extends State<DataStatusPage> {
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

  /// 永続化の確認用にサンプル値を書き込む。診断フローは Step 2 で作る。
  Future<void> _saveSample() async {
    const sample = UserProfile(
      personalColor: PersonalColorType.spring,
      kokkaku: KokkakuType.wave,
    );
    final profile = sample.copyWith(birthday: DateTime(2008, 5, 14));
    await widget.profileRepository.save(profile);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  Future<void> _clear() async {
    await widget.profileRepository.clear();
    if (!mounted) return;
    setState(() => _profile = const UserProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ラキカラ')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _error;
    if (error != null) {
      return Padding(
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
      );
    }

    final masters = _masters!;
    final missing = masters.missingContentReport();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Step 1 の確認用画面です。Step 2 で診断フローに置き換えます。'),
        const SizedBox(height: 24),
        _SectionTitle('マスタ読み込み'),
        _StatusRow('色マスタ', '${masters.colors.length} 件'),
        _StatusRow('PCタイプ属性', '${masters.personalColorAttributes.length} 件'),
        _StatusRow('骨格タイプ属性', '${masters.kokkakuAttributes.length} 件'),
        _StatusRow('PC診断の設問', '${masters.personalColorQuestions.length} 問'),
        _StatusRow('骨格診断の設問', '${masters.kokkakuQuestions.length} 問'),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '※ まだ仮データです:\n${missing.map((item) => '・$item').join('\n')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        _SectionTitle('プロフィール（端末内のみ）'),
        if (_profile.isEmpty)
          const Text('未設定')
        else ...[
          _StatusRow('パーソナルカラー', _profile.personalColor?.label ?? '未設定'),
          _StatusRow('骨格', _profile.kokkaku?.label ?? '未設定'),
          _StatusRow('星座', _profile.zodiac?.label ?? '未設定'),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: _saveSample,
              child: const Text('サンプルを保存'),
            ),
            OutlinedButton(onPressed: _clear, child: const Text('クリア')),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '保存後にアプリを完全に終了して開き直すと、値が残っていることを確認できます。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
