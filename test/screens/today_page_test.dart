import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/daily_fortune_source.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/models/daily_fortune.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/user_profile.dart';
import 'package:rakikara/screens/today_page.dart';

import '../data/master_repository_test.dart' show validSources;

/// 指定した占いをそのまま返す。配信の実装に依存せず画面だけを見る。
class StubFortuneSource implements DailyFortuneSource {
  StubFortuneSource(this.fortune, {this.error});

  final DailyFortune? fortune;
  final Object? error;
  Zodiac? requestedZodiac;

  @override
  Future<DailyFortune?> fetch({required Zodiac zodiac, required DateTime date}) async {
    requestedZodiac = zodiac;
    if (error != null) throw error!;
    return fortune;
  }
}

void main() {
  final masters = const MasterRepository().parse(validSources());

  final profile = UserProfile(
    personalColor: PersonalColorType.spring,
    kokkaku: KokkakuType.wave,
    birthday: DateTime(2008, 5, 14), // 牡牛座
  );

  DailyFortune fortune(String luckyColorId) => DailyFortune(
        date: DateTime(2026, 8, 21),
        zodiac: Zodiac.taurus,
        message: '今日はいい日になりそう。',
        luckyColorId: luckyColorId,
        luckyItemCategory: ItemCategory.nail,
      );

  /// 提案カードは縦に長い。テストの既定画面（800x600）だと ListView が
  /// 3枚目を作らないため、実機に近い縦長にしてから描画する。
  Future<void> pumpPage(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1170, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  Widget page(
    DailyFortuneSource source, {
    UserProfile? withProfile,
    Future<bool> Function(Uri)? openUrl,
  }) {
    return MaterialApp(
      home: TodayPage(
        masters: masters,
        profile: withProfile ?? profile,
        fortuneSource: source,
        today: DateTime(2026, 8, 21),
        openUrl: openUrl,
      ),
    );
  }

  testWidgets('ラッキーカラーが似合う色のとき、その色の提案が並ぶ', (tester) async {
    await pumpPage(tester, page(StubFortuneSource(fortune('coral_pink'))));

    expect(find.text('牡牛座の今日'), findsOneWidget);
    expect(find.text('今日はいい日になりそう。'), findsOneWidget);
    expect(find.text('今日のコーデ'), findsOneWidget);
    expect(find.text('今日のネイル'), findsOneWidget);
    expect(find.text('今日のヘアアクセ'), findsOneWidget);
    expect(find.textContaining('コーラルピンク'), findsWidgets);
    expect(find.text('今日の推し'), findsOneWidget);
  });

  testWidgets('ラッキーカラーが似合う色でないとき、少量取り入れの提案になる', (tester) async {
    await pumpPage(tester, page(StubFortuneSource(fortune('royal_blue'))));

    expect(find.textContaining('ちょこっとだけ取り入れる'), findsOneWidget);
    expect(find.textContaining('主役は得意な色で'), findsNWidgets(2));
  });

  testWidgets('占いが娯楽目的である旨を必ず出す', (tester) async {
    await pumpPage(tester, page(StubFortuneSource(fortune('coral_pink'))));

    expect(find.text('占いの内容は娯楽目的のものです。'), findsOneWidget);
  });

  testWidgets('プロフィールの星座で占いを取りにいく', (tester) async {
    final source = StubFortuneSource(fortune('coral_pink'));
    await pumpPage(tester, page(source));

    expect(source.requestedZodiac, Zodiac.taurus);
  });

  testWidgets('楽天でさがすを押すと検索URLが開かれる', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      page(
        StubFortuneSource(fortune('coral_pink')),
        openUrl: (url) async {
          opened.add(url);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('楽天でさがす').first);
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(opened.single.host, 'search.rakuten.co.jp');
    expect(Uri.decodeComponent(opened.single.toString()), contains('コーラルピンク'));
  });

  testWidgets('リンクを開けなかったらその旨を出す', (tester) async {
    await tester.pumpWidget(
      page(
        StubFortuneSource(fortune('coral_pink')),
        openUrl: (url) async => false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('楽天でさがす').first);
    await tester.pumpAndSettle();

    expect(find.text('リンクを開けませんでした'), findsOneWidget);
  });

  testWidgets('誕生日未登録なら登録をうながす', (tester) async {
    await tester.pumpWidget(
      page(
        StubFortuneSource(fortune('coral_pink')),
        withProfile: const UserProfile(personalColor: PersonalColorType.spring),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('誕生日を登録すると'), findsOneWidget);
  });

  testWidgets('その日の占いが未配信ならその旨を出し、再読み込みできる', (tester) async {
    await pumpPage(tester, page(StubFortuneSource(null)));

    expect(find.text('今日の占いはまだ配信されていません。'), findsOneWidget);
    expect(find.text('再読み込み'), findsOneWidget);
  });

  testWidgets('取得に失敗したらエラーを出し、再試行できる', (tester) async {
    await tester.pumpWidget(
      page(StubFortuneSource(null, error: StateError('通信エラー'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日の占いを取れませんでした'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });
}
