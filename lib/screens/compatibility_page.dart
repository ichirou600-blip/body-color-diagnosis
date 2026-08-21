import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';

import '../data/master_data.dart';
import '../logic/compatibility.dart';
import '../models/enums.dart';

/// 相性診断。自分の星座 × 相手の誕生日から相性テキストを出す。
class CompatibilityPage extends StatefulWidget {
  const CompatibilityPage({
    super.key,
    required this.masters,
    required this.myZodiac,
    this.today,
  });

  final MasterData masters;

  /// 自分の星座。誕生日未登録なら null。
  final Zodiac? myZodiac;

  /// テストから日付を固定するため。省略時は今日。
  final DateTime? today;

  @override
  State<CompatibilityPage> createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends State<CompatibilityPage> {
  CompatibilityResult? _result;
  Zodiac? _partnerZodiac;
  bool _notFound = false;

  Future<void> _pickPartnerBirthday() async {
    final now = widget.today ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 16, 1, 1),
      firstDate: DateTime(now.year - 80, 1, 1),
      lastDate: now,
      helpText: '相手の誕生日をえらぶ',
    );
    if (picked == null) return;

    final myZodiac = widget.myZodiac;
    if (myZodiac == null) return;

    final result = judgeCompatibility(
      masters: widget.masters,
      myZodiac: myZodiac,
      partnerBirthday: picked,
    );
    setState(() {
      _result = result;
      _partnerZodiac = Zodiac.fromDate(picked);
      _notFound = result == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myZodiac = widget.myZodiac;

    return Scaffold(
      appBar: AppBar(title: const Text('相性診断')),
      bottomNavigationBar: const BannerAdSlot(),
      body: SafeArea(
        child: myZodiac == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('自分の誕生日を登録すると、相性診断ができます。'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('あなたは${myZodiac.label}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(
                    '相手の誕生日を入れると、ふたりの相性が出ます。'
                    '入れた誕生日は保存も送信もされません。',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _pickPartnerBirthday,
                    child: Text(
                      _partnerZodiac == null ? '相手の誕生日を入れる' : '相手を変える',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_notFound)
                    Text(
                      'この組み合わせのテキストがまだ準備できていません。',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (_result case final result?) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${result.myZodiac.label} × ${result.partnerZodiac.label}',
                              style: theme.textTheme.titleLarge,
                            ),
                            if (result.isSameZodiac) ...[
                              const SizedBox(height: 4),
                              Text('同じ星座同士', style: theme.textTheme.labelMedium),
                            ],
                            const SizedBox(height: 12),
                            Text(result.text, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // docs/SPEC.md §8: 占いは娯楽目的である旨を必ず添える
                    Text(
                      '占いの内容は娯楽目的のものです。',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
