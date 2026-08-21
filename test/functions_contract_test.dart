import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/firestore_daily_fortune_source.dart';
import 'package:rakikara/models/daily_fortune.dart';
import 'package:rakikara/models/enums.dart';

/// Cloud Functions（`functions/`）とアプリの間の取り決めを固定する。
///
/// 生成側とアプリでIDがズレると、「配信された色がアプリに存在しない」
/// という、実行するまで気づけない壊れ方をする。ここで機械的に突き合わせる。
void main() {
  /// TypeScript の `export const NAME = [ "a", "b" ] as const;` から文字列を取り出す。
  List<String> readStringArray(String source, String name) {
    final match = RegExp(
      'export const $name = \\[(.*?)\\] as const;',
      dotAll: true,
    ).firstMatch(source);
    expect(match, isNotNull, reason: '$name の定義が見つかりません');
    return RegExp('"([^"]+)"')
        .allMatches(match!.group(1)!)
        .map((m) => m.group(1)!)
        .toList();
  }

  test('生成AIに選ばせる色IDが、色マスタと完全に一致する', () {
    final master = jsonDecode(File('assets/color_master.json').readAsStringSync())
        as Map<String, dynamic>;
    final masterIds = [
      for (final color in master['colors'] as List) (color as Map)['id'] as String,
    ];

    final generated = readStringArray(
      File('functions/src/colorIds.ts').readAsStringSync(),
      'COLOR_IDS',
    );

    expect(
      generated,
      masterIds,
      reason: 'functions/ で `npm run sync-color-ids` を実行してください',
    );
  });

  test('星座IDが Zodiac と一致する', () {
    final generated = readStringArray(
      File('functions/src/fortune.ts').readAsStringSync(),
      'ZODIAC_IDS',
    );

    expect(generated, [for (final zodiac in Zodiac.values) zodiac.id]);
  });

  test('アイテムカテゴリIDが ItemCategory と一致する', () {
    final generated = readStringArray(
      File('functions/src/fortune.ts').readAsStringSync(),
      'ITEM_CATEGORY_IDS',
    );

    expect(generated, [for (final category in ItemCategory.values) category.id]);
  });

  test('Firestore の保存先パスが、生成側と読み取り側で一致する', () {
    final functionsSource = File('functions/src/index.ts').readAsStringSync();

    expect(
      functionsSource,
      contains('collection("${FirestoreDailyFortuneSource.collectionName}")'),
    );
    expect(
      functionsSource,
      contains(
        'collection("${FirestoreDailyFortuneSource.zodiacSubcollectionName}")',
      ),
    );
  });

  test('セキュリティルールが占い以外の読み書きを禁じている', () {
    final rules = File('firestore.rules').readAsStringSync();

    // user コレクションを作らない方針をルール側でも担保する（docs/SPEC.md §5）
    expect(rules, contains('match /{document=**}'));
    expect(rules, contains('allow read, write: if false;'));
    // アプリからの書き込みは禁止。書くのは Admin SDK だけ。
    expect(rules, contains('allow write: if false;'));
  });
}
