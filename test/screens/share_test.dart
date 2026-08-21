import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/logic/share_image.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/user_profile.dart';
import 'package:rakikara/screens/share_card.dart';
import 'package:rakikara/screens/share_page.dart';

import '../data/master_repository_test.dart' show validSources;

/// 共有シートを開かずに、渡されたものだけ記録する。
class RecordingShareService extends ShareImageService {
  RecordingShareService({this.failOnCapture = false});

  final bool failOnCapture;
  Uint8List? sharedBytes;
  String? sharedText;
  Rect? sharedOrigin;
  int captureCount = 0;

  @override
  Future<Uint8List> capture(GlobalKey boundaryKey, {double pixelRatio = 3}) async {
    captureCount++;
    if (failOnCapture) throw StateError('書き出せませんでした');
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<void> share(
    Uint8List pngBytes, {
    String fileName = 'rakikara.png',
    String? text,
    Rect? origin,
  }) async {
    sharedBytes = pngBytes;
    sharedText = text;
    sharedOrigin = origin;
  }
}

void main() {
  final masters = const MasterRepository().parse(validSources());

  final fullProfile = UserProfile(
    personalColor: PersonalColorType.spring,
    kokkaku: KokkakuType.wave,
    birthday: DateTime(2008, 5, 14),
  );

  Widget wrap(Widget child) => MaterialApp(home: child);

  group('ShareCard', () {
    testWidgets('診断済みの内容が載る', (tester) async {
      await tester.pumpWidget(
        wrap(ShareCard(masters: masters, profile: fullProfile)),
      );

      expect(find.text('ラキカラ'), findsOneWidget);
      expect(find.text('イエベ春'), findsOneWidget);
      expect(find.text('ウェーブ'), findsOneWidget);
      expect(find.text('牡牛座'), findsOneWidget);
      expect(find.text('#ラキカラ'), findsOneWidget);
    });

    testWidgets('未診断の項目は「未診断」と出る', (tester) async {
      await tester.pumpWidget(
        wrap(
          ShareCard(
            masters: masters,
            profile: const UserProfile(personalColor: PersonalColorType.spring),
          ),
        ),
      );

      expect(find.text('イエベ春'), findsOneWidget);
      expect(find.text('未診断'), findsNWidgets(2)); // 骨格と星座
    });
  });

  group('SharePage', () {
    testWidgets('シェアを押すと、書き出した画像がそのまま渡される', (tester) async {
      final service = RecordingShareService();
      await tester.pumpWidget(
        wrap(
          SharePage(masters: masters, profile: fullProfile, shareService: service),
        ),
      );

      await tester.tap(find.text('この画像をシェアする'));
      await tester.pumpAndSettle();

      expect(service.captureCount, 1);
      expect(service.sharedBytes, [1, 2, 3]);
      expect(service.sharedText, contains('ラキカラ'));
      // iPad で共有シートを開くのに要る。ボタンの矩形が渡っていること。
      expect(service.sharedOrigin, isNotNull);
      expect(service.sharedOrigin!.isEmpty, isFalse);
    });

    testWidgets('書き出しに失敗したらエラーを出し、画面は落ちない', (tester) async {
      final service = RecordingShareService(failOnCapture: true);
      await tester.pumpWidget(
        wrap(
          SharePage(masters: masters, profile: fullProfile, shareService: service),
        ),
      );

      await tester.tap(find.text('この画像をシェアする'));
      await tester.pumpAndSettle();

      expect(find.textContaining('シェア画像を作れませんでした'), findsOneWidget);
      expect(service.sharedBytes, isNull);
      // 失敗後もボタンは押せる状態に戻っている
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
    });
  });

  group('ShareImageService.capture', () {
    testWidgets('RepaintBoundary から実際に PNG を書き出せる', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        wrap(
          Center(
            child: RepaintBoundary(
              key: key,
              child: ShareCard(masters: masters, profile: fullProfile),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 画像の書き出しは実際の非同期処理なので runAsync が要る。
      final bytes = await tester.runAsync(
        () => const ShareImageService().capture(key, pixelRatio: 2),
      );

      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(1000));
      // PNG のシグネチャ
      expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    });

    testWidgets('描画されていないキーを渡したら例外にする', (tester) async {
      await tester.pumpWidget(wrap(const SizedBox()));

      expect(
        () => const ShareImageService().capture(GlobalKey()),
        throwsA(isA<StateError>()),
      );
    });
  });
}
