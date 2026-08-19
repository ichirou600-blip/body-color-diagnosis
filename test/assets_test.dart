import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';

/// `assets/` に実際に置いてあるJSONが読めることを確認する。
///
/// 本コンテンツに差し替えたときも、このテストが最初に落ちる場所になる。
/// **件数（40色 / 12通り / 78件 / 各10問）はここでは検証しない**。
/// 仮データのままでも CI を通す必要があるため。件数は
/// `MasterData.missingContentReport()` が実行時に報告する。
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

  test('仮データの状態が missingContentReport で分かる', () async {
    final masters = await const MasterRepository().load();

    // 本コンテンツを入れ終わったらこのリストは空になる。
    // そのときこのテストは「本データが揃った」ことを示す形に書き換える。
    expect(masters.missingContentReport(), isNotEmpty);
  });
}
