import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// メモリ上のJSONを返す [AssetBundle]。
///
/// `testWidgets` は FakeAsync ゾーンで動くため、実ファイルI/Oを伴う `rootBundle`
/// からの読み込みは完了せずテストがハングする。ウィジェットテストではこれを注入する。
/// 実際の `assets/` が読めることは `test/assets_test.dart`（通常の `test`）で確認している。
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.sources);

  final Map<String, String> sources;

  @override
  Future<ByteData> load(String key) async {
    final source = sources[key];
    if (source == null) {
      throw FlutterError('FakeAssetBundle にキー "$key" がありません');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(source)));
  }

  // CachingAssetBundle は大きなペイロードで compute() を挟むことがあり、
  // FakeAsync 下で完了しない。テスト用途では常に同期的にデコードする。
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final source = sources[key];
    if (source == null) {
      throw FlutterError('FakeAssetBundle にキー "$key" がありません');
    }
    return source;
  }
}
