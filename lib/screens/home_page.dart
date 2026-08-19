import 'package:flutter/material.dart';

import '../data/master_data.dart';
import '../logic/diagnosis_scoring.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import 'diagnosis_page.dart';
import 'personal_color_result_page.dart';

/// ホーム画面。プロフィールの現状と、各診断への入口を出す。
///
/// Step 2 時点ではパーソナルカラー診断だけ。骨格診断は Step 3、
/// 今日のおすすめ・占いは Step 5 以降で足す（`docs/SPEC.md` §9）。
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.masters,
    required this.profile,
    required this.onProfileChanged,
  });

  final MasterData masters;
  final UserProfile profile;

  /// 診断結果を保存するときに呼ぶ。永続化は呼び出し側の責務。
  final Future<void> Function(UserProfile profile) onProfileChanged;

  /// 結果画面から「もう一度診断する」で再入するため、[BuildContext] ではなく
  /// [NavigatorState] を受け取る。pop 済みの画面の context は使えないため。
  Future<void> _startPersonalColorDiagnosis(NavigatorState navigator) async {
    final answers = await navigator.push<DiagnosisAnswers>(
      MaterialPageRoute(
        builder: (_) => DiagnosisPage(
          title: 'パーソナルカラー診断',
          questions: masters.personalColorQuestions,
        ),
      ),
    );
    if (answers == null) return; // 途中でやめた

    final result = scoreDiagnosis(
      questions: masters.personalColorQuestions,
      candidates: PersonalColorType.values,
      idOf: (type) => type.id,
      answers: answers,
    );
    await onProfileChanged(profile.copyWith(personalColor: result.type));

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => PersonalColorResultPage(
          masters: masters,
          type: result.type,
          onRetry: () => _startPersonalColorDiagnosis(navigator),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = masters.missingContentReport();

    return Scaffold(
      appBar: AppBar(title: const Text('ラキカラ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('あなたのタイプ', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ProfileRow(
              label: 'パーソナルカラー',
              value: profile.personalColor?.label,
            ),
            _ProfileRow(label: '骨格', value: profile.kokkaku?.label),
            _ProfileRow(label: '星座', value: profile.zodiac?.label),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _startPersonalColorDiagnosis(Navigator.of(context)),
              child: Text(
                profile.personalColor == null
                    ? 'パーソナルカラー診断をはじめる'
                    : 'パーソナルカラーを診断しなおす',
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '骨格診断・今日の占い・今日のおすすめは順次追加されます。',
              style: theme.textTheme.bodySmall,
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '※ コンテンツはまだ仮データです:\n'
                '${missing.map((item) => '・$item').join('\n')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value ?? '未診断')],
      ),
    );
  }
}
