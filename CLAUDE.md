# CLAUDE.md

診断×占い 掛け合わせアプリ **「ラキカラ」**（JK向け）のリポジトリ。

## 最重要

**実装判断はすべて `docs/SPEC.md`（要件定義書・実装計画書 v1）に従う。**
仕様と矛盾する実装はしない。仕様に書かれていない判断が必要になったら、勝手に決めずに確認する。

## 進め方

- `docs/SPEC.md` §9 の実装ステップを **1ステップずつ** 進める。指示されていない先のステップを先回りして作らない
- 各ステップは §9 の「完了条件」を満たしたら止めて報告する
- 現在のステップ: **Step 0（Flutter雛形 → Codemagic → TestFlight貫通）**
  - コード側は完了。残りは Apple / Codemagic のアカウント操作（`docs/STEP0_SETUP.md`）

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
- Firebase: Firestore（`daily_fortune` の読み取り専用配信のみ）、Cloud Functions（毎朝5:00 JST の scheduled バッチ）
- CI/CD: Codemagic → TestFlight
- 広告: AdMob（バナー＋ネイティブ。リワードは P1）

## 未決事項の扱い（`docs/SPEC.md` §11）

- ~~アプリ名~~ → **「ラキカラ」で決定済み**（`docs/SPEC.md` §1）。bundle ID / package 名は `com.ichirou600.rakikara`。App Store Connect にアプリレコードを作成した後は変更できないので、勝手に変えない
- 楽天アフィリエイトID未取得。リンク生成関数は ID を定数で外出しし、空でも動く形にする

## コンテンツ（静的JSON）

`assets/` 配下の以下はチャット側で作成してから配置する。Claude Code 側で中身を勝手に生成・水増ししない（作成中の仮データを置く場合は仮であることを明示する）:

`color_master.json` / `type_attributes.json` / `pc_x_kokkaku.json` / `compatibility.json` / `questions.json`

## 掛け合わせエンジン

- 入力 `(user_profile, daily_fortune, マスタ群)` → 出力 `提案カードのリスト` のインターフェースを固定する
- **新しい掛け合わせ = ルール関数を1つ追加するだけ**で画面に反映される構造を崩さない
