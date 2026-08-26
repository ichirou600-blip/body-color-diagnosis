import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/app_links.dart';

/// 公開するプライバシーポリシーが、アプリの実装と食い違っていないか見張る。
///
/// 実装を変えたのにポリシーが古いまま、という状態はストア審査でも
/// 利用者との関係でも問題になる。文言の存在だけでも機械的に確認しておく。
void main() {
  final policy = File('docs/privacy/index.html').readAsStringSync();

  test('アプリが送信しないと約束しているものが書かれている', () {
    for (final phrase in const [
      '収集しません',
      '診断の回答および診断結果',
      '入力された誕生日',
      '端末内にのみ保存',
    ]) {
      expect(policy, contains(phrase), reason: phrase);
    }
  });

  test('広告の方針が書かれている', () {
    // docs/SPEC.md §2 / CLAUDE.md の「絶対に破らないルール」3
    expect(policy, contains('非パーソナライズ広告'));
    expect(policy, contains('ATT'));
    expect(policy, contains('表示しません'));
  });

  test('対象年齢と、子供向けカテゴリに登録しない旨が書かれている', () {
    expect(policy, contains('13歳以上'));
    expect(policy, contains('ファミリー'));
  });

  test('占いが娯楽目的である旨が書かれている', () {
    expect(policy, contains('娯楽'));
  });

  test('アプリが参照するURLが https である', () {
    final uri = Uri.parse(AppLinks.privacyPolicy);
    expect(uri.scheme, 'https');
    expect(uri.host, isNotEmpty);
  });
}
