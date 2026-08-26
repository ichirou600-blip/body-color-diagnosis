import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';

import '../data/daily_fortune_source.dart';
import '../data/master_data.dart';
import '../logic/diagnosis_scoring.dart';
import '../logic/personal_color_judge.dart';
import '../models/enums.dart';
import '../models/master_models.dart';
import '../models/user_profile.dart';
import 'about_page.dart';
import 'compatibility_page.dart';
import 'diagnosis_page.dart';
import 'kokkaku_result_page.dart';
import 'personal_color_result_page.dart';
import 'share_page.dart';
import 'today_page.dart';
import 'style_match_card.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_widgets.dart';

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
    this.appVersion,
  });

  final MasterData masters;
  final UserProfile profile;
  final ProfileUpdater onProfileChanged;

  /// Step 5 時点では端末内の仮データ。Step 6 で Firestore 実装に差し替える。
  final DailyFortuneSource fortuneSource;

  /// 「このアプリについて」に出すバージョン。取得できなければ null。
  final String? appVersion;

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
    final diagnosed = profile.personalColor != null || profile.kokkaku != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ラキカラ'),
        actions: [
          IconButton(
            tooltip: 'このアプリについて',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AboutPage(version: appVersion),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdSlot(),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _ProfileHeader(profile: profile),
              const SizedBox(height: 20),
              StyleMatchCard(
                masters: masters,
                personalColor: profile.personalColor,
                kokkaku: profile.kokkaku,
              ),
              const SizedBox(height: 28),
              const SectionLabel('しんだんする', color: AppColors.blush),
              const SizedBox(height: 12),
              _MenuTile(
                emoji: '🎨',
                title: 'パーソナルカラー診断',
                subtitle: profile.personalColor == null
                    ? '10問で似合う色がわかる'
                    : '結果: ${profile.personalColor!.label}',
                tint: AppColors.blushSoft,
                done: profile.personalColor != null,
                actionLabel: profile.personalColor == null
                    ? 'パーソナルカラー診断をはじめる'
                    : 'パーソナルカラーを診断しなおす',
                onTap: () => _startPersonalColor(Navigator.of(context)),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                emoji: '👗',
                title: '骨格診断',
                subtitle: profile.kokkaku == null
                    ? '10問で似合うシルエットがわかる'
                    : '結果: ${profile.kokkaku!.label}',
                tint: AppColors.lavenderSoft,
                done: profile.kokkaku != null,
                actionLabel: profile.kokkaku == null ? '骨格診断をはじめる' : '骨格を診断しなおす',
                onTap: () => _startKokkaku(Navigator.of(context)),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                emoji: '🎂',
                title: '誕生日',
                subtitle: profile.zodiac == null
                    ? '登録すると占いが読める'
                    : profile.zodiac!.label,
                tint: AppColors.butterSoft,
                done: profile.birthday != null,
                actionLabel:
                    profile.birthday == null ? '誕生日を登録する' : '誕生日を変更する',
                onTap: () => _pickBirthday(context),
              ),
              const SizedBox(height: 28),
              const SectionLabel('あそぶ', color: AppColors.mint),
              const SizedBox(height: 12),
              _MenuTile(
                emoji: '✨',
                title: '今日のおすすめ',
                subtitle: '運勢とラッキーカラーの掛け合わせ',
                tint: AppColors.mintSoft,
                actionLabel: '今日のおすすめを見る',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TodayPage(
                      masters: masters,
                      profile: profile,
                      fortuneSource: fortuneSource,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                emoji: '💞',
                title: '相性診断',
                subtitle: '気になる人の誕生日でチェック',
                tint: AppColors.blushSoft,
                actionLabel: '相性をしらべる',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CompatibilityPage(
                      masters: masters,
                      myZodiac: profile.zodiac,
                    ),
                  ),
                ),
              ),
              if (diagnosed || profile.birthday != null) ...[
                const SizedBox(height: 12),
                _MenuTile(
                  emoji: '📸',
                  title: 'シェア',
                  subtitle: '結果をカードにして送れる',
                  tint: AppColors.lavenderSoft,
                  actionLabel: '結果をシェアする',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SharePage(masters: masters, profile: profile),
                    ),
                  ),
                ),
              ],
              if (missing.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  '※ コンテンツはまだ仮データです:\n'
                  '${missing.map((item) => '・$item').join('\n')}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 画面上部のプロフィール。3つのタイプを横並びのバッジで見せる。
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('あなたのタイプ', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              _ProfileRow(
                label: 'カラー',
                value: profile.personalColor?.label,
                tint: AppColors.blushSoft,
              ),
              const SizedBox(width: 10),
              _ProfileRow(
                label: '骨格',
                value: profile.kokkaku?.label,
                tint: AppColors.lavenderSoft,
              ),
              const SizedBox(width: 10),
              _ProfileRow(
                label: '星座',
                value: profile.zodiac?.label,
                tint: AppColors.butterSoft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// メニュー1件。絵文字・見出し・説明とボタンをまとめたカード。
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.actionLabel,
    required this.onTap,
    this.done = false,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color tint;
  final String actionLabel;
  final VoidCallback onTap;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (done) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle,
                          size: 16, color: AppColors.mint),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          // 見出しだけでなく操作の名前も残す。テストと読み上げの手がかりになる
          Semantics(
            button: true,
            label: actionLabel,
            child: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value, required this.tint});

  final String label;
  final String? value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSet = value != null;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSet ? tint : AppColors.line.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(
              value ?? '未診断',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSet ? AppColors.ink : AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
