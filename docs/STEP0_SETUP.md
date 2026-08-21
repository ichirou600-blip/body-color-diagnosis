# Step 0 セットアップ手順（Codemagic → TestFlight 貫通）

`docs/SPEC.md` §9 Step 0 の完了条件は **「実機の TestFlight で雛形アプリが起動する」**。
コード側（Flutter 雛形・`codemagic.yaml`）はリポジトリに入っているので、残りは Apple / Codemagic のアカウント操作。

## 確定している値

| 項目 | 値 |
|---|---|
| アプリ名（表示名） | ラキカラ |
| ストア表記 | ラキカラ - パーソナルカラー診断＆毎日占い |
| bundle ID / applicationId | `com.ichirou600.rakikara` |
| Dart パッケージ名 | `rakikara` |
| Flutter バージョン | 3.47.0（`codemagic.yaml` で固定） |

> **bundle ID は App Store Connect にアプリレコードを作った後は変更できない。** 作成前に上記で確定してよいか最終確認すること。

## 1. Apple 側の準備

1. **Apple Developer Program に加入**（有料・年間更新）。加入済みならスキップ
2. **App ID を登録** — [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
   - Identifier: `com.ichirou600.rakikara`
   - Capabilities: Step 0 では追加不要（Push は v1.1 で有効化）
3. **App Store Connect でアプリレコードを作成** — [My Apps](https://appstoreconnect.apple.com/apps) > ＋
   - プラットフォーム: iOS
   - 名前: `ラキカラ`（※ストア表示名。30文字以内）
   - プライマリ言語: 日本語
   - バンドルID: 上で作った `com.ichirou600.rakikara`
   - SKU: 任意（例 `rakikara-ios`）
4. **App Store Connect API キーを発行** — [Users and Access > Integrations > App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
   - アクセス権限: `App Manager`
   - 発行後に **Issuer ID / Key ID / `.p8` ファイル** を控える（`.p8` は一度しかダウンロードできない）
   - `.p8` は**リポジトリに絶対にコミットしない**

## 2. Codemagic 側の準備

1. Codemagic に GitHub でサインイン → **このリポジトリを接続**
2. **Teams** を開き、**チームは作らずに一覧の「自分の個人アカウント」をクリック** →
   **Integrations** → **Developer Portal** の **Connect** で、1-4 で取得した
   Issuer ID / Key ID / `.p8` を登録
   - ここで付ける**キー名を `RAKIKARA_ASC_KEY` にする**。別名にする場合は `codemagic.yaml` の `app_store_connect:` の値を合わせて変更する
   - チーム作成は複数人で使うための機能で、今回は不要
3. アプリ設定を **「codemagic.yaml を使う」** に切り替える（UI 設定ではなくリポジトリの yaml を読ませる）
4. `codemagic.yaml` の `TODO:` を2箇所置き換える
   - `app_store_connect: RAKIKARA_ASC_KEY` … 2 で付けたキー名
   - `recipients: - your-address@example.com` … ビルド通知の宛先

## 3. ビルドと配信

1. Codemagic で **`iOS - TestFlight`** ワークフローを実行
   - `flutter analyze` → `flutter test` → 署名 → `flutter build ipa` → TestFlight アップロードまで自動
2. App Store Connect > TestFlight で処理完了を待つ（数分〜30分）
3. **内部テスターに自分を追加**し、iPhone の TestFlight アプリからインストール
4. 起動して「ラキカラ」の雛形画面が出れば **Step 0 完了**

`Android - build check` ワークフローは APK が生成できることの確認のみ。Play への配信とリリース署名は Step 9 で追加する。

## 4. 詰まりやすいポイント

| 症状 | 原因・対処 |
|---|---|
| 署名エラー（no matching profiles） | App ID 未登録、または Codemagic の API キーの権限不足。`App Manager` 権限か確認 |
| TestFlight で「輸出コンプライアンス」を毎回聞かれる | `Info.plist` に `ITSAppUsesNonExemptEncryption = false` を設定済みなので本来は出ない。出る場合は値が消えていないか確認（HTTPS のみの利用なので免除対象） |
| TestFlight でビルドが配布できない | 「テスト情報」（連絡先・フィードバックメール）が未入力だと配布できない |
| ビルド番号の重複で弾かれる | 同じ `BUILD_NUMBER` で2回上げている。Codemagic の再実行ではなく新規ビルドとして流す |
| Codemagic の無料枠を使い切る | macOS インスタンスは消費が早い。失敗ビルドを繰り返さないよう、まず `Android - build check` で `analyze`/`test` を通してから iOS を回す |

## 5. Step 0 では**やらないこと**

- ストア審査提出（Step 9）。`submit_to_app_store: false` にしてある
- 年齢レーティング設定・プライバシーポリシー入力（Step 9）
- 「子供向け／ファミリー」カテゴリには登録しない（`docs/SPEC.md` §8）
- Firebase / AdMob の組み込み（Step 6 / Step 8）
