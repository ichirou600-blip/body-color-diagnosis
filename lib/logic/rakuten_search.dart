/// 楽天の検索URLを組み立てる。
///
/// アフィリエイトIDは未取得（`docs/SPEC.md` §11）。
/// **IDが空でも、素の検索URLとして成立する形にしてある**ので、
/// 取得できたら [affiliateId] を差すだけで全リンクがアフィリエイトリンクになる。
class RakutenSearch {
  const RakutenSearch._();

  /// 楽天アフィリエイトID。
  ///
  /// ビルド時に `--dart-define=RAKUTEN_AFFILIATE_ID=xxxx` で差し込む。
  /// リポジトリに直書きしないのは、IDの差し替えでアプリのコードを触りたくないため。
  ///
  /// 注意: 楽天のアフィリエイトコードはリンクの種類によって値が変わる。
  /// 取得後、実際に発行されるリンクと突き合わせて確認すること。
  static const String affiliateId =
      String.fromEnvironment('RAKUTEN_AFFILIATE_ID');

  static bool get hasAffiliateId => affiliateId.isNotEmpty;

  /// 色名とカテゴリ名で楽天の検索結果を開くURL。
  ///
  /// 例: コーラルピンク × ネイルシール → 「コーラルピンク ネイルシール」で検索
  static Uri searchUrl({
    required String colorName,
    required String categoryKeyword,
  }) {
    final keyword = '$colorName $categoryKeyword';
    final plain = Uri.parse(
      'https://search.rakuten.co.jp/search/mall/${Uri.encodeComponent(keyword)}/',
    );
    return hasAffiliateId ? _asAffiliateLink(plain) : plain;
  }

  /// 素のURLをアフィリエイト経由のURLに包む。
  ///
  /// 形式は `https://hb.afl.rakuten.co.jp/hgc/{ID}/?pc={PC用URL}&m={モバイル用URL}`。
  /// スマホアプリなので pc / m とも同じURLを渡す。
  static Uri _asAffiliateLink(Uri target) {
    final encoded = Uri.encodeComponent(target.toString());
    return Uri.parse(
      'https://hb.afl.rakuten.co.jp/hgc/$affiliateId/?pc=$encoded&m=$encoded',
    );
  }
}
