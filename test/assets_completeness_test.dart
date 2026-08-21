import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/models/enums.dart';

/// 同梱コンテンツが本データとして揃っているかを検証する。
///
/// 構造の検証は `MasterRepository` が起動時に行う（`test/assets_test.dart`）。
/// こちらは「件数が想定どおりか」「文言のルールを破っていないか」を見る。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('想定件数がすべて揃っている', () async {
    final masters = await const MasterRepository().load();

    expect(
      masters.missingContentReport(),
      isEmpty,
      reason: 'docs/SPEC.md §5 の想定件数に届いていない項目があります',
    );
  });

  test('PC×骨格の12通りすべてにテキストがある', () async {
    final masters = await const MasterRepository().load();

    for (final pc in PersonalColorType.values) {
      for (final kokkaku in KokkakuType.values) {
        expect(
          masters.styleTextFor(pc, kokkaku),
          isNotNull,
          reason: '${pc.label} × ${kokkaku.label}',
        );
      }
    }
  });

  test('星座相性は78通りすべてが、どちらの向きでも引ける', () async {
    final masters = await const MasterRepository().load();

    for (final a in Zodiac.values) {
      for (final b in Zodiac.values) {
        expect(
          masters.compatibilityTextFor(a, b),
          isNotNull,
          reason: '${a.label} × ${b.label}',
        );
        expect(
          masters.compatibilityTextFor(a, b),
          masters.compatibilityTextFor(b, a),
          reason: '${a.label} × ${b.label} は順序を変えても同じテキストであること',
        );
      }
    }
  });

  test('各PCタイプに似合う色が登録されている', () async {
    final masters = await const MasterRepository().load();

    for (final pc in PersonalColorType.values) {
      expect(
        masters.colorsForPersonalColor(pc),
        isNotEmpty,
        reason: pc.label,
      );
    }
  });

  test('コンテンツに禁止表現が混ざっていない', () async {
    // docs/SPEC.md §8 の表現ルール。体型へのネガティブな言及・ダイエット誘導・
    // 容姿の優劣は、審査落ちと炎上の両方につながるため機械的に弾く。
    const forbidden = [
      'ダイエット',
      '痩せ',
      'やせ',
      '太っ',
      '太る',
      '体型カバー',
      '細く見せ',
      'ぽっちゃり',
      'がっしり',
      'ムチムチ',
      'デブ',
      'スタイルが悪',
      '着太り',
    ];

    for (final path in const [
      MasterRepository.colorMasterPath,
      MasterRepository.typeAttributesPath,
      MasterRepository.pcXKokkakuPath,
      MasterRepository.compatibilityPath,
      MasterRepository.questionsPath,
    ]) {
      final root = jsonDecode(await rootBundle.loadString(path));
      // 覚え書きの `_note` は開発者向けなので検査対象から外す。
      if (root is Map) root.remove('_note');
      final source = jsonEncode(root);

      for (final word in forbidden) {
        expect(
          source.contains(word),
          isFalse,
          reason: '$path に禁止表現 "$word" が含まれています',
        );
      }
    }
  });
}
