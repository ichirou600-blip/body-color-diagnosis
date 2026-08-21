import '../models/daily_fortune.dart';
import '../models/enums.dart';

/// その日の占いを取ってくる口。
///
/// Step 5 では端末内の仮データ [LocalDailyFortuneSource] を使う。
/// Step 6 で Firestore から読む実装に差し替える（`docs/SPEC.md` §9）。
/// 画面はこのインターフェースにだけ依存させて、差し替えで済むようにしておく。
abstract class DailyFortuneSource {
  Future<DailyFortune?> fetch({required Zodiac zodiac, required DateTime date});
}

/// 配信前に画面を組むための仮実装。
///
/// 日付と星座から決まるので、同じ日に開けば同じ結果が出る。
/// **Step 6 で Firestore 実装に差し替える。それまでの足場。**
class LocalDailyFortuneSource implements DailyFortuneSource {
  const LocalDailyFortuneSource();

  static const List<String> _messages = [
    'いつもの道をちょっと変えてみると、いいことがありそう。',
    '人に頼るのが上手くいく日。ひとりで抱えないほうが早い。',
    '思いつきで動いたほうが当たる日。迷ったら先に手を動かして。',
    '静かに整える日。部屋でも机でも、片付けた分だけ気分が軽くなる。',
    '誰かの一言が刺さる日。素直に受け取ると得をする。',
    '見た目を少し変えると流れが変わる。髪でも爪でもいい。',
  ];

  /// 色マスタに実在するIDから選ぶ。
  /// Step 6 では Cloud Functions 側が同じ制約で選ぶ（`docs/SPEC.md` §7）。
  static const List<String> _luckyColorIds = [
    'coral_pink',
    'powder_blue',
    'terracotta',
    'royal_blue',
    'lavender',
    'mustard',
    'emerald_green',
    'baby_pink',
  ];

  @override
  Future<DailyFortune?> fetch({
    required Zodiac zodiac,
    required DateTime date,
  }) async {
    final seed = date.year * 10000 + date.month * 100 + date.day + zodiac.index;
    return DailyFortune(
      date: DateTime(date.year, date.month, date.day),
      zodiac: zodiac,
      message: _messages[seed % _messages.length],
      luckyColorId: _luckyColorIds[seed % _luckyColorIds.length],
      luckyItemCategory: ItemCategory.values[seed % ItemCategory.values.length],
    );
  }
}
