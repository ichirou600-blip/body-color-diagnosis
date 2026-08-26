import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/app_links.dart';
import 'package:rakikara/screens/about_page.dart';
import 'package:rakikara/theme/app_theme.dart';

void main() {
  Widget page({Future<bool> Function(Uri)? openUrl, String? version = '1.0.0 (3)'}) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: AboutPage(version: version, openUrl: openUrl),
    );
  }

  testWidgets('占いが娯楽目的である旨を出す', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.textContaining('娯楽目的'), findsOneWidget);
  });

  testWidgets('診断が優劣を決めるものではないと明記する', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.textContaining('似合うものを見つける'), findsOneWidget);
    expect(find.textContaining('良し悪しを決めるものではありません'), findsOneWidget);
  });

  testWidgets('端末内にしか保存しないと明記する', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.textContaining('どこにも送信されません'), findsOneWidget);
  });

  testWidgets('バージョンを表示する。取れなくても落ちない', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('バージョン 1.0.0 (3)'), findsOneWidget);

    await tester.pumpWidget(page(version: null));
    await tester.pumpAndSettle();
    expect(find.text('バージョン —'), findsOneWidget);
  });

  testWidgets('プライバシーポリシーを押すと公開URLが開かれる', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(page(openUrl: (url) async {
      opened.add(url);
      return true;
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pumpAndSettle();

    expect(opened.single.toString(), AppLinks.privacyPolicy);
    expect(opened.single.scheme, 'https');
  });

  testWidgets('リンクを開けなかったらその旨を出す', (tester) async {
    await tester.pumpWidget(page(openUrl: (url) async => false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('プライバシーポリシー'));
    await tester.pumpAndSettle();

    expect(find.text('リンクを開けませんでした'), findsOneWidget);
  });

  testWidgets('ライセンス画面を開ける', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    await tester.tap(find.text('ライセンス'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
