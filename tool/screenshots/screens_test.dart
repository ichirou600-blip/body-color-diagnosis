import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/ads/ad_config.dart';
import 'package:rakikara/data/daily_fortune_source.dart';
import 'package:rakikara/data/master_data.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/user_profile.dart';
import 'package:rakikara/screens/compatibility_page.dart';
import 'package:rakikara/screens/diagnosis_page.dart';
import 'package:rakikara/screens/home_page.dart';
import 'package:rakikara/screens/personal_color_result_page.dart';
import 'package:rakikara/screens/today_page.dart';
import 'package:rakikara/theme/app_theme.dart';

void main() {
  late MasterData masters;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('MPLUSRounded1c')
      ..addFont(rootBundle.load('assets/fonts/MPLUSRounded1c-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/MPLUSRounded1c-Bold.ttf'));
    await loader.load();
    // アイコンフォントはテスト環境に無いので、SDK のものを読み込む
    final icons = FontLoader('MaterialIcons')
      ..addFont(File(
        '/home/user/flutter-sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes().then(ByteData.sublistView));
    await icons.load();
    masters = await const MasterRepository().load();
  });

  final profile = UserProfile(
    personalColor: PersonalColorType.spring,
    kokkaku: KokkakuType.wave,
    birthday: DateTime(2008, 5, 14),
  );

  Future<void> shoot(WidgetTester tester, String name, Widget child) async {
    tester.view.physicalSize = const Size(1170, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: AdsScope(config: AdConfig.disabled, child: child),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
  }

  testWidgets('home', (t) => shoot(t, '1_home', HomePage(
        masters: masters,
        profile: profile,
        onProfileChanged: (_) async {},
      )));

  testWidgets('question', (t) => shoot(t, '2_question', DiagnosisPage(
        title: 'パーソナルカラー診断',
        questions: masters.personalColorQuestions,
      )));

  testWidgets('result', (t) => shoot(t, '3_result', PersonalColorResultPage(
        masters: masters,
        type: PersonalColorType.spring,
        kokkaku: KokkakuType.wave,
        onRetry: () {},
      )));

  testWidgets('today', (t) => shoot(t, '4_today', TodayPage(
        masters: masters,
        profile: profile,
        fortuneSource: const LocalDailyFortuneSource(),
        today: DateTime(2026, 8, 24),
      )));

  testWidgets('compat', (t) => shoot(t, '5_compat', CompatibilityPage(
        masters: masters,
        myZodiac: Zodiac.taurus,
        today: DateTime(2026, 8, 24),
      )));
}
