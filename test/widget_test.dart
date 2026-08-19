import 'package:flutter_test/flutter_test.dart';

import 'package:rakikara/main.dart';

void main() {
  testWidgets('雛形画面にアプリ名とキャッチコピーが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const RakikaraApp());

    expect(find.text('ラキカラ'), findsOneWidget);
    expect(find.text('パーソナルカラー診断＆毎日占い'), findsOneWidget);
  });
}
