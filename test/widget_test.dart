import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/master_repository_test.dart' show validSources;
import 'support/fake_asset_bundle.dart';

/// 3問すべて "a" を選ぶとイエベ春、"b" を選ぶとブルベ冬になる質問セット。
const String _threeQuestions = '''
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
 "kokkaku":[]}''';

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
    app = buildApp(questions: _threeQuestions);
  });

  Future<void> answerAll(WidgetTester tester, String suffix) async {
    for (var i = 1; i <= 3; i++) {
      await tester.tap(find.text('設問$iの$suffix'));
      await tester.pumpAndSettle();
    }
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

    await tester.tap(find.text('パーソナルカラー診断をはじめる'));
    await tester.pumpAndSettle();
    expect(find.text('Q1 / 3'), findsOneWidget);

    await answerAll(tester, '春');

    expect(find.text('診断結果'), findsOneWidget);
    expect(find.text('イエベ春'), findsOneWidget);
  });

  testWidgets('選んだ回答によって判定が変わる', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('パーソナルカラー診断をはじめる'));
    await tester.pumpAndSettle();
    await answerAll(tester, '冬');

    expect(find.text('ブルベ冬'), findsOneWidget);
  });

  testWidgets('判定結果が保存され、アプリを作り直しても残る', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('パーソナルカラー診断をはじめる'));
    await tester.pumpAndSettle();
    await answerAll(tester, '春');
    await tester.tap(find.text('ホームに戻る'));
    await tester.pumpAndSettle();

    expect(find.text('イエベ春'), findsOneWidget);
    expect(find.text('パーソナルカラーを診断しなおす'), findsOneWidget);

    // 端末の再起動に相当する
    await tester.pumpWidget(buildApp(questions: _threeQuestions));
    await tester.pumpAndSettle();

    expect(find.text('イエベ春'), findsOneWidget);
  });

  testWidgets('途中で戻るとプロフィールは変わらない', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('パーソナルカラー診断をはじめる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設問1の春'));
    await tester.pumpAndSettle();

    // Q2 から戻るボタンを2回押すとホームまで戻る
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('未診断'), findsNWidgets(3));
  });

  testWidgets('マスタが壊れていればエラー表示になり、再試行できる', (tester) async {
    await tester.pumpWidget(buildApp(colorMaster: '{壊れたJSON'));
    await tester.pumpAndSettle();

    expect(find.text('マスタの読み込みに失敗しました'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });
}
