# TestFlight 実機確認チェックリスト

Step 0 以降に広告・Firebase・シェアと実機でしか確認できない機能が積み上がっている。
ここまでの分をまとめて実機で確認するための、**上から順にやる手順**。

所要時間の目安: Apple の審査待ちを除いて 2〜3時間。ビルドは無料枠（月500分・macOS）で足りる。Apple Developer Program の
加入審査に1〜2日かかることがあるので、まだなら **A-1 を最初に着手する**。

コード側は準備済み。**Firebase と AdMob の設定は今回不要**（未設定でもアプリは動く）。
まずビルドと配信を通すことに集中する。

---

## A. Apple 側（初回のみ）

### A-1. Apple Developer Program に加入する

https://developer.apple.com/programs/ から加入する（有料・年間更新）。
**加入審査に1〜2日かかることがある。**加入済みなら次へ。

### A-2. App ID を登録する

1. https://developer.apple.com/account/resources/identifiers/list を開く
2. 「＋」→ **App IDs** → **App** を選ぶ
3. Description: `Rakikara`（任意）
4. Bundle ID: **Explicit** を選び、`com.ichirou600.rakikara` と入力
   - **この値は後から変更できない。**タイプミスに注意
5. Capabilities は何も追加せず登録

### A-3. App Store Connect にアプリを作る

1. https://appstoreconnect.apple.com/apps を開く
2. 「＋」→ **新規アプリ**
3. 入力値
   - プラットフォーム: **iOS**
   - 名前: **ラキカラ**
   - プライマリ言語: **日本語**
   - バンドルID: A-2 で作った `com.ichirou600.rakikara` を選ぶ
   - SKU: `rakikara-ios`（任意の管理用文字列）
   - ユーザーアクセス: フルアクセス
4. 作成

### A-4. App Store Connect API キーを発行する

1. https://appstoreconnect.apple.com/access/integrations/api を開く
2. 「＋」でキーを生成
   - 名前: `Codemagic`
   - アクセス: **App Manager**
3. 生成後、次の3つを控える
   - **Issuer ID**（ページ上部に表示される）
   - **Key ID**
   - **`.p8` ファイル**（ダウンロードは1回きり。再取得できない）
4. `.p8` は **リポジトリに絶対にコミットしない**

---

## B. Codemagic 側（初回のみ）

### B-1. サインアップとリポジトリ接続

1. https://codemagic.io/ に GitHub アカウントでサインイン
2. `ichirou600-blip/body-color-diagnosis` を追加する

### B-2. App Store Connect の連携を登録する

1. 左メニューの **Teams** を開く
2. **チームは作らない。**一覧に並んでいる**自分の個人アカウント**をクリックする
   （「Create team」を押すと不要なチーム作成フォームが出る。× で閉じてよい）
3. **Integrations** を開き、**Developer Portal** の **Connect** を押す
4. A-4 で控えた値を入れる

| 項目 | 値 |
|---|---|
| App Store Connect API key name | **`RAKIKARA_ASC_KEY`** |
| Issuer ID | A-4 の Issuer ID |
| Key ID | A-4 の Key ID |
| API key | A-4 の `.p8` ファイル |

**この key name を `codemagic.yaml` の `app_store_connect:` が参照している。**
別名にするなら `codemagic.yaml` 側も合わせて変える。
登録後の追加・削除は同じ画面の「Manage keys」から。

### B-3. codemagic.yaml を使う設定にする

アプリの設定画面で **「Use codemagic.yaml」** に切り替える。
UI 上のビルド設定ではなく、リポジトリの `codemagic.yaml` を読ませる。

### B-4. 通知先メールを設定する

`codemagic.yaml` の以下を自分のメールアドレスに書き換えてコミットする。

```yaml
      email:
        recipients:
          - your-address@example.com   # ← ここ
```

---

## C. ビルドと配信

### C-1. iOS ワークフローを回す

1. アプリ画面の **Start new build**
2. Branch: `claude/diagnosis-fortune-app-spec-r3rt91`
3. **Select file workflow: `iOS - TestFlight`**
4. **Start new build**

署名 → `flutter build ipa` → TestFlight へのアップロードまで自動。
ビルドは15〜30分程度かかる（Firebase の Pod が多いため初回は長い）。

`analyze` / `test` / Functions の型チェックは iOS ワークフローの先頭で走るので、
コード側に問題があればビルドの早い段階で止まる。**Android を先に回す必要はない。**

> 無料プランで使えるインスタンスは **`mac_mini_m2`（macOS）だけ**で、
> 月500分まで。Android ワークフローも同じ macOS 上で動くため、
> 先に回しても消費が減るわけではない。Android の APK 確認は
> Google Play に出す Step 9 の段階でよい。

### C-2. （任意）Android ワークフロー

`Android - build check` は APK が生成できることの確認用。
Play への配信とリリース署名は Step 9 で追加する。

### C-3. TestFlight の設定

1. App Store Connect → 対象アプリ → **TestFlight** タブ
2. ビルドの処理完了を待つ（数分〜30分。「処理中」表示が消える）
3. **テスト情報** を入力する（未入力だと配布できない）
   - フィードバックメールアドレス
   - 連絡先情報
4. **内部テスト** グループに自分を追加する

### C-4. 実機で確認する

iPhone に TestFlight アプリを入れて、ラキカラをインストールする。

---

## D. 実機で見るべきこと

上から順に触って、結果を記録する。**うまく動かない項目があれば、その項目名を伝えてほしい。**

| # | 操作 | 期待する結果 |
|---|---|---|
| 1 | アプリを起動 | ホーム画面が出る。アイコン名が「ラキカラ」 |
| 2 | 画面下部 | バナー広告が出る。「Test Ad」と表示される |
| 3 | パーソナルカラー診断 → 10問回答 | 結果画面にタイプ・説明・似合う色が出る |
| 4 | 結果画面 | ネイティブ広告が出る（「Test Ad」表示） |
| 5 | 骨格診断 → 10問回答 | 結果に加えて「◯◯ × ◯◯ に似合うスタイル」が出る |
| 6 | ホームに戻る | パーソナルカラーと骨格が両方残っている |
| 7 | アプリを完全終了して再起動 | 診断結果が消えていない |
| 8 | 誕生日を登録 | 星座が表示される |
| 9 | 今日のおすすめ | 運勢文と提案カード3枚。「占いの内容は娯楽目的のものです。」の注記がある |
| 10 | 「楽天でさがす」を押す | ブラウザで楽天の検索結果が開く |
| 11 | 相性をしらべる → 相手の誕生日を入れる | 相性テキストが出る |
| 12 | 結果をシェアする → この画像をシェアする | 共有シートが開き、カード画像が渡る |
| 13 | 共有シートで「画像を保存」 | 写真アプリに保存される |

### 診断の精度についても見てほしい

3 と 5 で出た結果が、自分の実感と合っているか。合わないと感じたら、
**どの設問で迷ったか**を教えてほしい。配点の調整だけで直せる
（`questions.json` の差し替え。コード変更は不要）。

友達にも試してもらえると精度の判断材料が増える。

---

## この段階で「出なくて正常」なもの

| 見えるもの | 理由 |
|---|---|
| 占いが毎日同じ文面に見える | Firebase 未設定なので端末内の仮データを使っている。Step 6 の設定後に本物の配信に切り替わる |
| 広告に「Test Ad」と出る | テスト用の広告ユニットIDを使っている。本番IDへの差し替えは `docs/STEP8_SETUP.md` |
| 楽天リンクにアフィリエイトIDが付かない | ID未取得のため素の検索URL。取得後に `--dart-define` で差し込む |

---

## 詰まったときに見るところ

| 症状 | 原因・対処 |
|---|---|
| No matching profiles found for bundle identifier ... | `codemagic.yaml` の `ios_signing`（手動アップロードした署名ファイルを選ぶ指定）では、無いプロファイルは作られない。API キーから `app-store-connect fetch-signing-files --create` で作らせる方式に変更済み |
| 署名で別のエラーが出る | A-2 の App ID が未登録か Bundle ID の綴り違い、A-4 のキーが App Manager 権限でない、developer.apple.com に契約書の同意待ちバナーが出ている、のいずれか |
| CocoaPods でバージョンエラー | Firebase は iOS 15.0 以上が必要。プロジェクトは 15.0 に設定済みなので、通常は起きない |
| TestFlight にビルドが出てこない | 処理に最大30分かかる。App Store Connect の「アクティビティ」でエラーが出ていないか確認 |
| TestFlight で配布できない | C-3 の「テスト情報」が未入力 |
| ビルド番号の重複で弾かれる | 同じビルド番号で2回アップロードしている。再実行ではなく新規ビルドとして流す |
| 起動直後に落ちる | ログを送ってほしい。Firebase / AdMob の初期化失敗は握りつぶす作りなので、別の原因の可能性が高い |
| The selected instance type is not available with the current billing plan | 無料プランで使えるのは `mac_mini_m2` のみ。`linux_x2` などは課金を有効にしたアカウント専用 |
| 無料枠を使い切りそう | 無料枠は月500分。失敗ビルドを繰り返さないよう、ログで原因を特定してから回し直す |
