import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/screens/compatibility_page.dart';

import '../data/master_repository_test.dart' show validSources;

void main() {
  // 相手の誕生日ピッカーの初期値は「今日の16年前の1月1日」＝ 山羊座。
  // その組み合わせのテキストを持たせておく。
  final masters = const MasterRepository().parse(
    validSources(
      compatibility: '''
{"version":1,"entries":[
 {"zodiac_a":"taurus","zodiac_b":"capricorn","text":"地のサイン同士、テンポが合うふたり。"}]}''',
    ),
  );

  Widget page({Zodiac? myZodiac = Zodiac.taurus}) {
    return MaterialApp(
      home: CompatibilityPage(
        masters: masters,
        myZodiac: myZodiac,
        today: DateTime(2026, 8, 21),
      ),
    );
  }

  testWidgets('相手の誕生日を入れると相性テキストが出る', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.text('あなたの星座'), findsOneWidget);
    expect(find.text('牡牛座'), findsOneWidget);

    await tester.tap(find.text('相手の誕生日を入れる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // 初期値（2010-01-01）＝山羊座で確定
    await tester.pumpAndSettle();

    expect(find.text('牡牛座 × 山羊座'), findsOneWidget);
    expect(find.text('地のサイン同士、テンポが合うふたり。'), findsOneWidget);
    expect(find.text('相手を変える'), findsOneWidget);
  });

  testWidgets('占いが娯楽目的である旨を出す', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    // 結果が出る前は注記も出さない
    expect(find.text('占いの内容は娯楽目的のものです。'), findsNothing);

    await tester.tap(find.text('相手の誕生日を入れる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('占いの内容は娯楽目的のものです。'), findsOneWidget);
  });

  testWidgets('相手の誕生日は保存も送信もされないと明記する', (tester) async {
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    expect(find.textContaining('保存も送信もされません'), findsOneWidget);
  });

  testWidgets('自分の誕生日が未登録なら、登録をうながす', (tester) async {
    await tester.pumpWidget(page(myZodiac: null));
    await tester.pumpAndSettle();

    expect(find.textContaining('自分の誕生日を登録すると'), findsOneWidget);
    expect(find.text('相手の誕生日を入れる'), findsNothing);
  });

  testWidgets('テキストが未登録の組み合わせなら、その旨を出す', (tester) async {
    await tester.pumpWidget(page(myZodiac: Zodiac.leo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('相手の誕生日を入れる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.textContaining('まだ準備できていません'), findsOneWidget);
  });
}
