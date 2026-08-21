# CLAUDE.md

診断×占い 掛け合わせアプリ **「ラキカラ」**（JK向け）のリポジトリ。

## 最重要

**実装判断はすべて `docs/SPEC.md`（要件定義書・実装計画書 v1）に従う。**
仕様と矛盾する実装はしない。仕様に書かれていない判断が必要になったら、勝手に決めずに確認する。

## 進め方

- `docs/SPEC.md` §9 の実装ステップを **1ステップずつ** 進める。指示されていない先のステップを先回りして作らない
- 各ステップは §9 の「完了条件」を満たしたら止めて報告する
- 現在のステップ: **実機確認（`docs/TESTFLIGHT_CHECKLIST.md`）→ その後 Step 9**
  - Step 6 はコード側完了。残りは Firebase / Anthropic のアカウント操作（`docs/STEP6_SETUP.md`）
  - Step 0 はコード側完了。残りは Apple / Codemagic のアカウント操作（`docs/STEP0_SETUP.md`）
  - Step 8 はコード側完了。テストIDで動作中。本番IDへの差し替えは `docs/STEP8_SETUP.md`
  - Step 1〜7 完了

## 絶対に破らないルール

1. **ユーザーの個人情報をサーバーに送らない**。誕生日・診断結果・プロフィールは端末ローカル（shared_preferences）のみ。Firestore に user コレクションを作らない
2. **Claude API キーをアプリ側に埋め込まない**。Cloud Functions の環境変数のみ。`assets/`・Dart コード・`.env`・リポジトリへのコミットすべて禁止
3. **広告は非パーソナライズ（NPA）を既定**。ATT プロンプトは出さない。AdMob の未成年配慮設定（TFUA等）を有効化する
4. **表現ルール**: 骨格・体型は「似合うものの提案」のみ。体型のネガティブ言及・ダイエット誘導・容姿の優劣表現は、コード内の文言・JSON コンテンツ・AI生成プロンプトすべてで禁止
5. **占いは娯楽目的**である旨の注記を、占い表示画面に必ず入れる
6. ストアの「子供向け／ファミリー」カテゴリには登録しない

## ローカル検証コマンド

コード変更後は必ず両方を通してから完了報告する（CI でも同じものが走る）:

```
flutter analyze
flutter test
```

## 技術スタック

- Flutter（iOS / Android）。iOS 優先だが Android も同時に動くこと
- Firebase: Firestore（`daily_fortune` の読み取り専用配信のみ）、Cloud Functions（毎朝5:00 JST の scheduled バッチ、`functions/`）
- Cloud Functions を変更したら `cd functions && npm run typecheck` を通す（CI でも走る）
- CI/CD: Codemagic → TestFlight
- 広告: AdMob（バナー＋ネイティブ。リワードは P1）

## 未決事項の扱い（`docs/SPEC.md` §11）

- ~~アプリ名~~ → **「ラキカラ」で決定済み**（`docs/SPEC.md` §1）。bundle ID / package 名は `com.ichirou600.rakikara`。App Store Connect にアプリレコードを作成した後は変更できないので、勝手に変えない
- 楽天アフィリエイトID未取得。`lib/logic/rakuten_search.dart` の `RakutenSearch.affiliateId` に `--dart-define=RAKUTEN_AFFILIATE_ID=xxxx` で差し込む。空でも素の検索URLとして動く

## コンテンツ（静的JSON）

対象ファイル: `color_master.json` / `type_attributes.json` / `pc_x_kokkaku.json` / `compatibility.json` / `questions.json`

- **JSONのキー名と検証ルールは `docs/DATA_SCHEMA.md` で確定済み。**
- 本データ投入済み。件数と文言ルールは `test/assets_completeness_test.dart` が検証する
- コンテンツ作成はユーザーの指示により Claude Code 側で実施した（当初は「チャット側で作成」の方針だったが変更）。**内容を変更したら必ず `flutter test` を通すこと**（禁止表現の混入を機械的に弾いている）

## 掛け合わせエンジン

- 入力 `(user_profile, daily_fortune, マスタ群)` → 出力 `提案カードのリスト` のインターフェースを固定する
- **新しい掛け合わせ = ルール関数を1つ追加するだけ**で画面に反映される構造を崩さない
