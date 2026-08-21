import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/master_repository_test.dart' show validSources;
import 'support/fake_asset_bundle.dart';

/// PC は3問すべて "春" を選ぶとイエベ春・"冬" ならブルベ冬、
/// 骨格は2問すべて "ウェーブ" ならウェーブ・"ナチュラル" ならナチュラルになる質問セット。
const String _questions = '''
{"version":1,
 "personal_color":[
  {"id":"pc_q01","text":"設問1","choices":[
    {"id":"a","text":"設問1の春","scores":{"spring":1}},
    {"id":"b","text":"設問1の冬","scores":{"winter":1}}]},
  {"id":"pc_q02","text":"設問2","choices":[
    {"id":"a","text":"設問2の春","scores":{"spring":1}},
    {"id":"b","text":"設問2の冬","scores":{"winter":1}}]},
  {"id":"pc_q03","text":"設問3","choices":[
    {"id":"a","text":"設問3の春","scores":{"spring":1}},
    {"id":"b","text":"設問3の冬","scores":{"winter":1}}]}],
 "kokkaku":[
  {"id":"kk_q01","text":"骨格1","choices":[
    {"id":"a","text":"骨格1のウェーブ","scores":{"wave":1}},
    {"id":"b","text":"骨格1のナチュラル","scores":{"natural":1}}]},
  {"id":"kk_q02","text":"骨格2","choices":[
    {"id":"a","text":"骨格2のウェーブ","scores":{"wave":1}},
    {"id":"b","text":"骨格2のナチュラル","scores":{"natural":1}}]}]}''';

void main() {
  late RakikaraApp app;

  RakikaraApp buildApp({String? questions, String? colorMaster}) {
    return RakikaraApp(
      masterRepository: MasterRepository(
        bundle: FakeAssetBundle(
          validSources(questions: questions, colorMaster: colorMaster),
        ),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    app = buildApp(questions: _questions);
  });

  /// パーソナルカラー診断の全3問に同じ傾向の選択肢で答える。
  Future<void> answerPersonalColor(WidgetTester tester, String suffix) async {
    for (var i = 1; i <= 3; i++) {
      await tester.tap(find.text('設問$iの$suffix'));
      await tester.pumpAndSettle();
    }
  }

  /// 骨格診断の全2問に同じ傾向の選択肢で答える。
  Future<void> answerKokkaku(WidgetTester tester, String suffix) async {
    for (var i = 1; i <= 2; i++) {
      await tester.tap(find.text('骨格$iの$suffix'));
      await tester.pumpAndSettle();
    }
  }

  /// ホームは縦に長いので、画面外のボタンはスクロールしてから押す。
  Future<void> tapOnHome(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// スクロールで画面外に出たプロフィール欄を、また見える位置まで戻す。
  Future<void> scrollHomeToTop(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('あなたのタイプ'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  /// ホームから診断を1つ通しで実行し、結果画面からホームに戻る。
  Future<void> runDiagnosis(
    WidgetTester tester, {
    required String startButton,
    required Future<void> Function(WidgetTester tester) answer,
  }) async {
    await tapOnHome(tester, startButton);
    await answer(tester);
    await tester.tap(find.text('ホームに戻る'));
    await tester.pumpAndSettle();
    await scrollHomeToTop(tester);
  }

  testWidgets('起動するとホームに未診断の状態が出る', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('ラキカラ'), findsOneWidget);
    expect(find.text('パーソナルカラー'), findsOneWidget);
    expect(find.text('未診断'), findsNWidgets(3));
    expect(find.text('パーソナルカラー診断をはじめる'), findsOneWidget);
  });

  testWidgets('全問回答すると判定され、結果が表示される', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tapOnHome(tester, 'パーソナルカラー診断をはじめる');
    expect(find.text('Q1 / 3'), findsOneWidget);

    await answerPersonalColor(tester, '春');

    expect(find.text('診断結果'), findsOneWidget);
    expect(find.text('イエベ春'), findsOneWidget);
  });

  testWidgets('選んだ回答によって判定が変わる', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tapOnHome(tester, 'パーソナルカラー診断をはじめる');
    await answerPersonalColor(tester, '冬');

    expect(find.text('ブルベ冬'), findsOneWidget);
  });

  testWidgets('判定結果が保存され、アプリを作り直しても残る', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tapOnHome(tester, 'パーソナルカラー診断をはじめる');
    await answerPersonalColor(tester, '春');
    await tester.tap(find.text('ホームに戻る'));
    await tester.pumpAndSettle();
    await scrollHomeToTop(tester);

    expect(find.text('イエベ春'), findsOneWidget);

    // 端末の再起動に相当する
    await tester.pumpWidget(buildApp(questions: _questions));
    await tester.pumpAndSettle();

    expect(find.text('イエベ春'), findsOneWidget);
  });

  testWidgets('途中で戻るとプロフィールは変わらない', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tapOnHome(tester, 'パーソナルカラー診断をはじめる');
    await tester.tap(find.text('設問1の春'));
    await tester.pumpAndSettle();

    // Q2 から戻るボタンを2回押すとホームまで戻る
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await scrollHomeToTop(tester);

    expect(find.text('未診断'), findsNWidgets(3));
  });

  testWidgets('骨格診断も同じ流れで判定・保存される', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tapOnHome(tester, '骨格診断をはじめる');
    expect(find.text('Q1 / 2'), findsOneWidget);

    await answerKokkaku(tester, 'ナチュラル');

    expect(find.text('ナチュラル'), findsOneWidget);

    await tester.tap(find.text('ホームに戻る'));
    await tester.pumpAndSettle();
    expect(find.text('骨格を診断しなおす'), findsOneWidget);
  });

  testWidgets('PCと骨格が揃うと掛け合わせのテキストが出る', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // 片方だけでは掛け合わせは出ず、何を診断すればよいかが出る
    await runDiagnosis(
      tester,
      startButton: 'パーソナルカラー診断をはじめる',
      answer: (tester) => answerPersonalColor(tester, '春'),
    );
    expect(find.text('骨格も診断すると、あなたに似合うスタイルが出ます。'), findsOneWidget);

    await runDiagnosis(
      tester,
      startButton: '骨格診断をはじめる',
      answer: (tester) => answerKokkaku(tester, 'ウェーブ'),
    );

    // fixture の pc_x_kokkaku は spring × wave のみ登録してある
    expect(find.text('イエベ春 × ウェーブ に似合うスタイル'), findsOneWidget);
    expect(find.text('春ウェーブ'), findsOneWidget);
  });

  testWidgets('骨格の結果画面にも掛け合わせのテキストが出る', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await runDiagnosis(
      tester,
      startButton: 'パーソナルカラー診断をはじめる',
      answer: (tester) => answerPersonalColor(tester, '春'),
    );
    await tapOnHome(tester, '骨格診断をはじめる');
    await answerKokkaku(tester, 'ウェーブ');

    expect(find.text('診断結果'), findsOneWidget);
    expect(find.text('春ウェーブ'), findsOneWidget);
  });

  testWidgets('片方を診断しなおしても、もう片方の結果は消えない', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await runDiagnosis(
      tester,
      startButton: 'パーソナルカラー診断をはじめる',
      answer: (tester) => answerPersonalColor(tester, '春'),
    );
    await runDiagnosis(
      tester,
      startButton: '骨格診断をはじめる',
      answer: (tester) => answerKokkaku(tester, 'ウェーブ'),
    );
    await runDiagnosis(
      tester,
      startButton: 'パーソナルカラーを診断しなおす',
      answer: (tester) => answerPersonalColor(tester, '冬'),
    );

    expect(find.text('ブルベ冬'), findsOneWidget);
    expect(find.text('ウェーブ'), findsOneWidget);
  });

  testWidgets('診断前はシェアの導線を出さない', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('結果をシェアする'), findsNothing);
  });

  testWidgets('診断するとホームからシェア画面を開ける', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await runDiagnosis(
      tester,
      startButton: 'パーソナルカラー診断をはじめる',
      answer: (tester) => answerPersonalColor(tester, '春'),
    );

    await tapOnHome(tester, '結果をシェアする');

    expect(find.text('シェア'), findsOneWidget);
    expect(find.text('#ラキカラ'), findsOneWidget);
    expect(find.text('この画像をシェアする'), findsOneWidget);
  });

  testWidgets('誕生日を登録すると星座が出る', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tapOnHome(tester, '誕生日を登録する');
    // ダイアログの初期表示は年選択ではなく日付グリッド。OK で初期値を確定する。
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await scrollHomeToTop(tester);

    expect(find.text('未診断'), findsNWidgets(2)); // 星座だけ埋まる
    expect(find.text('山羊座'), findsOneWidget);
  });

  testWidgets('ホームから今日のおすすめを開ける', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tapOnHome(tester, '今日のおすすめを見る');

    expect(find.text('今日のおすすめ'), findsOneWidget);
    // 誕生日未登録なので登録をうながす
    expect(find.textContaining('誕生日を登録すると'), findsOneWidget);
  });

  testWidgets('ホームから相性診断を開ける', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tapOnHome(tester, '相性をしらべる');

    expect(find.text('相性診断'), findsOneWidget);
    // 誕生日未登録なので登録をうながす
    expect(find.textContaining('自分の誕生日を登録すると'), findsOneWidget);
  });

  testWidgets('マスタが壊れていればエラー表示になり、再試行できる', (tester) async {
    await tester.pumpWidget(buildApp(colorMaster: '{壊れたJSON'));
    await tester.pumpAndSettle();

    expect(find.text('マスタの読み込みに失敗しました'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });
}
