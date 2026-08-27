# Step 6 セットアップ手順（Firebase 接続＋Functions バッチ）

`docs/SPEC.md` §9 Step 6 の完了条件は **「毎朝、当日の占いがアプリに反映される」**。
コード側（Cloud Functions・Firestore ルール・アプリの読み取り実装）はリポジトリに入っている。
残りは Firebase / Anthropic のアカウント操作。

## いまの状態

**設定前でもアプリは動く。** Firebase の設定ファイルが無い環境では初期化に失敗するが、
その場合は端末内の仮データに落ちる（`lib/data/fortune_source_factory.dart`）。
診断・シェア・相性診断は Firebase なしで動くので、設定が終わるまで開発とTestFlight配布は止まらない。

設定が済むと自動的に Firestore から読むようになる。アプリ側のコード変更は不要。

## Firebase プロジェクト

| 項目 | 値 |
|---|---|
| プロジェクト名 | `rakikara` |
| プロジェクトID | `rakikara-37acc` |
| プロジェクト番号 | `325542503092` |
| ロケーション | `asia-northeast1`（東京） |

Google アナリティクス・Gemini in Firebase はどちらも**無効**で作成した。
どちらもこのアプリでは使わない。

---

## 1. Firebase プロジェクトを作る

1. [Firebase コンソール](https://console.firebase.google.com/) でプロジェクトを作成
2. **Firestore Database** を作成
   - モード: 本番環境モード
   - ロケーション: `asia-northeast1`（東京）
3. **料金プラン を Blaze（従量課金）に変更**
   - Cloud Functions は Blaze でないと使えない。無料枠が大きいので実費はほぼ出ないが、
     カード登録は必要

## 2. アプリに Firebase をつなぐ

`flutterfire` CLI が設定ファイルの配置までやってくれる。

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=<プロジェクトID>
```

- iOS の bundle ID / Android の applicationId は **`com.ichirou600.rakikara`**（`docs/SPEC.md` §1）
- `ios/Runner/GoogleService-Info.plist` と `android/app/google-services.json` が生成される
- **この2ファイルはリポジトリにコミットしてよい**（公開鍵情報であり、秘密鍵ではない）。
  アクセス制御は `firestore.rules` 側で行う

## 3. Claude API キーを Secret Manager に入れる

**アプリ側には絶対に置かない**（`CLAUDE.md` の「絶対に破らないルール」2）。

1. [Anthropic Console](https://console.anthropic.com/) で API キーを発行
2. Secret Manager に登録する

```sh
cd functions
npm install
firebase functions:secrets:set ANTHROPIC_API_KEY
# プロンプトにキーを貼り付ける
```

## 4. デプロイ

```sh
# Firestore のセキュリティルール
firebase deploy --only firestore:rules

# バッチ関数
cd functions
npm run deploy
```

デプロイ後、Cloud Scheduler に `generateDailyFortunes` のジョブが作られる。

## 5. 動作確認

初回は翌朝5時を待たずに手で実行できる。

```sh
# Cloud Scheduler のジョブを今すぐ実行する
gcloud scheduler jobs run firebase-schedule-generateDailyFortunes-asia-northeast1 \
  --location=asia-northeast1
```

- Firebase コンソール > Firestore で `daily_fortune/{今日の日付}/zodiacs/` に12件できていれば成功
- アプリを起動して「今日のおすすめ」を開き、生成された運勢文が出れば **Step 6 完了**

## 設計上の決めごと

### 保存先

`daily_fortune/{YYYY-MM-DD}/zodiacs/{zodiacId}`

`docs/SPEC.md` §5 は `daily_fortune/{date}/{zodiac}` と書いているが、Firestore のパスは
コレクションとドキュメントが交互でなければならないため `zodiacs` を挟んでいる。意味は同じ。

### ユーザーデータは置かない

Firestore に入るのは星座単位の共有データだけ。誰が読んだかをサーバーは知らない。
`firestore.rules` は `daily_fortune` 以外のすべての読み書きを拒否しているので、
あとから誤って user コレクションを作ることもできない。

### 生成の制約

`functions/src/fortune.ts` が、構造化出力でJSONスキーマを強制している。

- `lucky_color_id` は **`assets/color_master.json` の40色のIDから選ばせる**（`z.enum`）
- `lucky_item_category` は3種から選ばせる
- 自由生成させると、アプリに存在しない色が配信されて掛け合わせが壊れる

色IDは手で写さない。`assets/color_master.json` から生成する。

```sh
cd functions && npm run sync-color-ids
```

ズレていないかは `test/functions_contract_test.dart` が `flutter test` で検証する。

### モデルとコスト

`claude-haiku-4-5` を使う（`docs/SPEC.md` §7 の「軽量モデルで十分」に従う）。
1日12回・1回あたり出力1000トークン未満なので、費用は月あたり数円の水準。
最新の料金は https://docs.claude.com で確認すること。

### 失敗したとき

- 1星座の生成に失敗しても、残りの星座は書き込む（全滅させない）
- 失敗があった場合は関数自体を失敗扱いにして、Cloud Functions の再試行（3回）に任せる
- それでも配信されなかった日は、アプリ側が「今日の占いはまだ配信されていません」と出す。
  アプリは落ちない

## 詰まりやすいポイント

| 症状 | 原因・対処 |
|---|---|
| `firebase deploy` で権限エラー | `firebase login` のアカウントがプロジェクトの編集者権限を持っているか確認 |
| 関数が Blaze プランを要求する | 料金プランを Blaze に変更する。無料枠内なら実費はほぼ出ない |
| アプリが仮データのままになる | 設定ファイルが配置されていない。`flutterfire configure` をやり直す。デバッグ実行時のログに理由が出る |
| 生成が毎回失敗する | Secret Manager のキー名が `ANTHROPIC_API_KEY` になっているか、キーが有効か確認 |
| Firestore に書けない | ルールではなく Admin SDK の権限の問題。関数のサービスアカウントを確認する（ルールは Admin SDK には適用されない） |
