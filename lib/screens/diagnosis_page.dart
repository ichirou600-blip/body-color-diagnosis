import 'package:flutter/material.dart';

import '../ads/banner_ad_slot.dart';

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
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('質問データがまだ入っていません。'),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_index + 1) / total),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Q${_index + 1} / $total',
                style: theme.textTheme.labelLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_question.text, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                // 選択肢を連打する画面なので、下端の広告と隣接させない。
                // 誤タップは AdMob の無効トラフィック扱いになりうる。
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  for (final choice in _question.choices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChoiceButton(
                        text: choice.text,
                        selected: choice.id == selected,
                        onPressed: () => _choose(choice.id),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.text,
    required this.selected,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
