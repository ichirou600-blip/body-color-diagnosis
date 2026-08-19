import '../models/master_models.dart';

/// 診断の回答。設問IDごとに選んだ選択肢ID。
typedef DiagnosisAnswers = Map<String, String>;

/// 集計結果。
class DiagnosisResult<T> {
  const DiagnosisResult({
    required this.type,
    required this.scores,
    required this.tiedTypes,
  });

  /// 判定されたタイプ。
  final T type;

  /// タイプごとの合計点。候補すべてのキーを持つ（0点も含む）。
  final Map<T, int> scores;

  /// 最高点が同点だったタイプ（[type] を含む）。1件なら同点なし。
  final List<T> tiedTypes;

  bool get wasTie => tiedTypes.length > 1;
}

/// 未回答の設問があるときに投げる。
class IncompleteDiagnosisException implements Exception {
  const IncompleteDiagnosisException(this.unansweredQuestionIds);

  final List<String> unansweredQuestionIds;

  @override
  String toString() =>
      'IncompleteDiagnosisException(未回答: ${unansweredQuestionIds.join(", ")})';
}

/// 回答を集計して最高点のタイプを返す。
///
/// PC診断・骨格診断で共用する（`docs/SPEC.md` §9 Step 2 / Step 3）。
///
/// 同点のときは [candidates] の並び順で先にあるものを採用する。
/// 呼び出し側は enum の `values` をそのまま渡すこと。並び順が
/// `docs/DATA_SCHEMA.md` の「共通のID語彙」の順序と一致している必要がある。
DiagnosisResult<T> scoreDiagnosis<T>({
  required List<Question> questions,
  required List<T> candidates,
  required String Function(T type) idOf,
  required DiagnosisAnswers answers,
}) {
  assert(candidates.isNotEmpty, '候補タイプが空です');

  final unanswered = [
    for (final question in questions)
      if (!answers.containsKey(question.id)) question.id,
  ];
  if (unanswered.isNotEmpty) {
    throw IncompleteDiagnosisException(unanswered);
  }

  final scores = {for (final candidate in candidates) candidate: 0};
  final idToCandidate = {for (final candidate in candidates) idOf(candidate): candidate};

  for (final question in questions) {
    final choiceId = answers[question.id];
    final choice = question.choices.where((c) => c.id == choiceId).firstOrNull;
    if (choice == null) {
      // 設問にない選択肢IDが渡された場合。UIからは起きないが、
      // 保存済みの古い回答を読み戻すときに起こりうるので黙って無視せず落とす。
      throw ArgumentError(
        '設問 "${question.id}" に選択肢 "$choiceId" がありません',
      );
    }
    choice.scores.forEach((typeId, points) {
      final candidate = idToCandidate[typeId];
      if (candidate != null) {
        scores[candidate] = scores[candidate]! + points;
      }
    });
  }

  final highest = scores.values.reduce((a, b) => a > b ? a : b);
  final tied = [
    for (final candidate in candidates)
      if (scores[candidate] == highest) candidate,
  ];

  return DiagnosisResult(
    type: tied.first,
    scores: Map.unmodifiable(scores),
    tiedTypes: List.unmodifiable(tied),
  );
}
