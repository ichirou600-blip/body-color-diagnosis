import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_widgets.dart';

import '../logic/diagnosis_scoring.dart';
import '../models/master_models.dart';

/// 1問ずつ選択肢を選ばせる診断画面。
///
/// PC診断・骨格診断で共用する。回答が揃ったら [DiagnosisAnswers] を持って pop する。
/// 途中でやめた場合は null を持って pop する。
class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({
    super.key,
    required this.title,
    required this.questions,
  });

  final String title;
  final List<Question> questions;

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  final DiagnosisAnswers _answers = {};
  int _index = 0;

  Question get _question => widget.questions[_index];
  bool get _isLast => _index == widget.questions.length - 1;

  void _choose(String choiceId) {
    _answers[_question.id] = choiceId;
    if (_isLast) {
      Navigator.of(context).pop(Map<String, String>.from(_answers));
      return;
    }
    setState(() => _index++);
  }

  void _back() {
    if (_index == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const GradientBackground(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('質問データがまだ入っていません。'),
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final total = widget.questions.length;
    final selected = _answers[_question.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: BackButton(onPressed: _back),
      ),
      bottomNavigationBar: const BannerAdSlot(),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Text(
                      'Q${_index + 1} / $total',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: AppColors.blush),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (_index + 1) / total,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SoftCard(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  child: Text(
                    _question.text,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  // 選択肢を連打する画面なので、下端の広告と隣接させない。
                  // 誤タップは AdMob の無効トラフィック扱いになりうる。
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  children: [
                    for (var i = 0; i < _question.choices.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChoiceButton(
                          index: i,
                          text: _question.choices[i].text,
                          selected: _question.choices[i].id == selected,
                          onPressed: () => _choose(_question.choices[i].id),
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

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.index,
    required this.text,
    required this.selected,
    required this.onPressed,
  });

  final int index;
  final String text;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 選択肢ごとに色を変えて、単調な一覧に見えないようにする
    final tint = AppColors.accentsSoft[index % AppColors.accentsSoft.length];
    final accent = AppColors.accents[index % AppColors.accents.length];

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      color: selected ? tint : Colors.white,
      onTap: onPressed,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? accent : tint,
              shape: BoxShape.circle,
            ),
            child: Text(
              String.fromCharCode(0x41 + index), // A, B, C...
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
