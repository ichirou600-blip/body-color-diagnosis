import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';

import '../data/daily_fortune_source.dart';
import '../data/master_data.dart';
import '../logic/diagnosis_scoring.dart';
import '../logic/personal_color_judge.dart';
import '../models/enums.dart';
import '../models/master_models.dart';
import '../models/user_profile.dart';
import 'compatibility_page.dart';
import 'diagnosis_page.dart';
import 'kokkaku_result_page.dart';
import 'personal_color_result_page.dart';
import 'share_page.dart';
import 'today_page.dart';
import 'style_match_card.dart';

/// プロフィール更新の依頼。常に最新の値を受け取って新しい値を返す。
typedef ProfileUpdater = Future<void> Function(
  UserProfile Function(UserProfile current) update,
);

/// ホーム画面。プロフィールの現状と、各診断への入口を出す。
///
/// Step 3 時点ではパーソナルカラー診断・骨格診断とその掛け合わせ表示まで。
/// 今日の占い・今日のおすすめは Step 5 以降で足す（`docs/SPEC.md` §9）。
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.masters,
    required this.profile,
    required this.onProfileChanged,
    this.fortuneSource = const LocalDailyFortuneSource(),
  });

  final MasterData masters;
  final UserProfile profile;
  final ProfileUpdater onProfileChanged;

  /// Step 5 時点では端末内の仮データ。Step 6 で Firestore 実装に差し替える。
  final DailyFortuneSource fortuneSource;

  /// 質問 → 判定 → 保存 → 結果画面 の一連。PC・骨格で共用する。
  ///
  /// 結果画面から「もう一度診断する」で再入するため、pop 済みの画面の
  /// [BuildContext] ではなく [NavigatorState] を受け取る。
  Future<void> _runDiagnosis<T>({
    required NavigatorState navigator,
    required String title,
    required List<Question> questions,
    required T Function(DiagnosisAnswers answers) judge,
    required UserProfile Function(UserProfile current, T type) apply,
    required Widget Function(T type, VoidCallback retry) resultPage,
  }) async {
    final answers = await navigator.push<DiagnosisAnswers>(
      MaterialPageRoute(
        builder: (_) => DiagnosisPage(title: title, questions: questions),
      ),
    );
    if (answers == null) return; // 途中でやめた

    final type = judge(answers);
    await onProfileChanged((current) => apply(current, type));

    void retry() => _runDiagnosis(
          navigator: navigator,
          title: title,
          questions: questions,
          judge: judge,
          apply: apply,
          resultPage: resultPage,
        );

    await navigator.push(
      MaterialPageRoute(builder: (_) => resultPage(type, retry)),
    );
  }

  Future<void> _startPersonalColor(NavigatorState navigator) {
    return _runDiagnosis<PersonalColorType>(
      navigator: navigator,
      title: 'パーソナルカラー診断',
      questions: masters.personalColorQuestions,
      judge: (answers) => judgePersonalColor(
        questions: masters.personalColorQuestions,
        answers: answers,
      ).type,
      apply: (current, type) => current.copyWith(personalColor: type),
      resultPage: (type, retry) => PersonalColorResultPage(
        masters: masters,
        type: type,
        kokkaku: profile.kokkaku,
        onRetry: retry,
      ),
    );
  }

  Future<void> _startKokkaku(NavigatorState navigator) {
    return _runDiagnosis<KokkakuType>(
      navigator: navigator,
      title: '骨格診断',
      questions: masters.kokkakuQuestions,
      judge: (answers) => scoreDiagnosis(
        questions: masters.kokkakuQuestions,
        candidates: KokkakuType.values,
        idOf: (type) => type.id,
        answers: answers,
      ).type,
      apply: (current, type) => current.copyWith(kokkaku: type),
      resultPage: (type, retry) => KokkakuResultPage(
        masters: masters,
        type: type,
        personalColor: profile.personalColor,
        onRetry: retry,
      ),
    );
  }

  /// 誕生日を選ぶ。星座はここから算出するので、日付そのものは端末内にしか置かない。
  Future<void> _pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final current = profile.birthday ?? DateTime(now.year - 16, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      // 主対象は13〜18歳。前後に余裕を持たせた範囲にしておく。
      firstDate: DateTime(now.year - 30, 1, 1),
      lastDate: now,
      helpText: '誕生日をえらぶ',
    );
    if (picked == null) return;
    await onProfileChanged((current) => current.copyWith(birthday: picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = masters.missingContentReport();

    return Scaffold(
      appBar: AppBar(title: const Text('ラキカラ')),
      bottomNavigationBar: const BannerAdSlot(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('あなたのタイプ', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ProfileRow(label: 'パーソナルカラー', value: profile.personalColor?.label),
            _ProfileRow(label: '骨格', value: profile.kokkaku?.label),
            _ProfileRow(label: '星座', value: profile.zodiac?.label),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TodayPage(
                    masters: masters,
                    profile: profile,
                    fortuneSource: fortuneSource,
                  ),
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('今日のおすすめを見る'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CompatibilityPage(
                    masters: masters,
                    myZodiac: profile.zodiac,
                  ),
                ),
              ),
              icon: const Icon(Icons.favorite_border),
              label: const Text('相性をしらべる'),
            ),
            const SizedBox(height: 24),
            StyleMatchCard(
              masters: masters,
              personalColor: profile.personalColor,
              kokkaku: profile.kokkaku,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _startPersonalColor(Navigator.of(context)),
              child: Text(
                profile.personalColor == null
                    ? 'パーソナルカラー診断をはじめる'
                    : 'パーソナルカラーを診断しなおす',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => _startKokkaku(Navigator.of(context)),
              child: Text(
                profile.kokkaku == null ? '骨格診断をはじめる' : '骨格を診断しなおす',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => _pickBirthday(context),
              child: Text(
                profile.birthday == null ? '誕生日を登録する' : '誕生日を変更する',
              ),
            ),
            if (!profile.isEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SharePage(masters: masters, profile: profile),
                  ),
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('結果をシェアする'),
              ),
            ],
            const SizedBox(height: 32),
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
