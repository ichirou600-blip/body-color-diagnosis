import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 結果カードを画像にして共有シートに渡す。
///
/// 端末の写真ライブラリへ直接保存する権限は要求しない。iOS / Android とも
/// 共有シートから「画像を保存」を選べるので、未成年向けアプリで権限ダイアログを
/// 増やさない判断（`docs/SPEC.md` §8 の方針に合わせる）。
///
/// テストから差し替えられるようにクラスにしてある。
class ShareImageService {
  const ShareImageService();

  /// [boundaryKey] が指す [RepaintBoundary] を PNG にする。
  ///
  /// [pixelRatio] は論理サイズに対する倍率。3 なら 360×450 の カード が
  /// 1080×1350 で書き出される。
  Future<Uint8List> capture(
    GlobalKey boundaryKey, {
    double pixelRatio = 3,
  }) async {
    final object = boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) {
      throw StateError('シェアカードがまだ描画されていません');
    }
    final image = await object.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('シェア画像の書き出しに失敗しました');
      }
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// PNG を一時ファイルに書いて共有シートを開く。
  ///
  /// 一時ディレクトリに置くのは、端末に残し続ける必要がないため。
  /// OS が適当なタイミングで回収する。
  ///
  /// [origin] は iPad で共有シートをポップオーバー表示する位置。
  /// iPad では未指定だと例外になるので、呼び出し側でボタンの矩形を渡す。
  Future<void> share(
    Uint8List pngBytes, {
    String fileName = 'rakikara.png',
    String? text,
    Rect? origin,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pngBytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  }
}
