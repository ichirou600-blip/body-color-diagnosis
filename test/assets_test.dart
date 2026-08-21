import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';

/// `assets/` に実際に置いてあるJSONが読めることを確認する。
///
/// 本コンテンツに差し替えたときも、このテストが最初に落ちる場所になる。
/// 件数と文言のルールは `test/assets_completeness_test.dart` で検証する。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('同梱のマスタJSONがすべて読み込める', () async {
    final masters = await const MasterRepository().load();

    expect(masters.colors, isNotEmpty);
    expect(masters.personalColorAttributes, hasLength(4));
    expect(masters.kokkakuAttributes, hasLength(3));
  });

  test('type_attributes の color_ids がすべて color_master に存在する', () async {
    // 参照切れがあれば load() が例外を投げるので、ここまで来れば整合している。
    final masters = await const MasterRepository().load();

    for (final attribute in masters.personalColorAttributes.values) {
      for (final colorId in attribute.colorIds) {
        expect(masters.colorById(colorId), isNotNull, reason: colorId);
      }
    }
  });

}
