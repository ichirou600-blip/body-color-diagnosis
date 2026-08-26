/// アプリの外に出るリンク。
///
/// URL はビルド時に差し替えられるようにしておく。ホスティング先を変えても
/// コードを触らずに済ませるため。
abstract final class AppLinks {
  /// プライバシーポリシーの公開URL。
  ///
  /// 既定値は GitHub Pages を `docs/` から公開したときのURL。
  /// 別の場所に置く場合は
  /// `--dart-define=PRIVACY_POLICY_URL=https://...` で差し替える。
  /// **App Store / Google Play の登録時にも同じURLを入れる。**
  static const String privacyPolicy = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue:
        'https://ichirou600-blip.github.io/body-color-diagnosis/privacy/',
  );
}
