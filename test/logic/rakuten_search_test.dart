import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/logic/rakuten_search.dart';

void main() {
  group('RakutenSearch', () {
    test('アフィリエイトID未設定でも、素の検索URLとして成立する', () {
      // --dart-define を渡していないビルドでの既定の挙動
      expect(RakutenSearch.hasAffiliateId, isFalse);

      final url = RakutenSearch.searchUrl(
        colorName: 'コーラルピンク',
        categoryKeyword: 'ネイルシール',
      );

      expect(url.host, 'search.rakuten.co.jp');
      expect(Uri.decodeComponent(url.path), '/search/mall/コーラルピンク ネイルシール/');
    });

    test('色名とカテゴリがURLエンコードされる', () {
      final url = RakutenSearch.searchUrl(
        colorName: 'オフホワイト',
        categoryKeyword: 'ヘアアクセサリー',
      );

      // 生のマルチバイト文字がURLに残っていないこと
      expect(url.toString(), isNot(contains('オフホワイト')));
      expect(Uri.decodeComponent(url.toString()), contains('オフホワイト ヘアアクセサリー'));
    });
  });
}
