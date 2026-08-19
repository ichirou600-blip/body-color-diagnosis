import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/master_repository_test.dart' show validSources;
import 'support/fake_asset_bundle.dart';

void main() {
  late RakikaraApp app;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    app = RakikaraApp(
      masterRepository: MasterRepository(bundle: FakeAssetBundle(validSources())),
    );
  });

  testWidgets('起動するとマスタの読み込み結果が表示される', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('ラキカラ'), findsOneWidget);
    expect(find.text('色マスタ'), findsOneWidget);
    expect(find.text('未設定'), findsOneWidget);
  });

  testWidgets('保存したプロフィールがアプリを作り直しても残る', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('サンプルを保存'));
    await tester.pumpAndSettle();
    expect(find.text('イエベ春'), findsOneWidget);

    // 端末の再起動に相当する。ウィジェットツリーを捨てて作り直しても、
    // shared_preferences から読み戻せていれば値が残る。
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('イエベ春'), findsOneWidget);
    expect(find.text('ウェーブ'), findsOneWidget);
    expect(find.text('牡牛座'), findsOneWidget);
  });

  testWidgets('クリアすると未設定に戻る', (tester) async {
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('サンプルを保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('クリア'));
    await tester.pumpAndSettle();

    expect(find.text('未設定'), findsOneWidget);
  });

  testWidgets('マスタが壊れていればエラー表示になり、再試行できる', (tester) async {
    await tester.pumpWidget(
      RakikaraApp(
        masterRepository: MasterRepository(
          bundle: FakeAssetBundle(validSources(colorMaster: '{壊れたJSON')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('マスタの読み込みに失敗しました'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });
}
