# Step 9 手順（アフィリリンク・プライバシーポリシー・ストア素材・審査提出）

`docs/SPEC.md` §9 Step 9 の完了条件は **「App Store / Google Play 審査提出完了」**。

コード側は完了している。残りはアカウント操作とストアへの入力。
**上から順にやれば、最後にリリースビルドを1回流して提出できる。**

---

## 1. プライバシーポリシーを公開する

文面は `docs/privacy/index.html` にある。そのまま公開できる1枚のHTML。

### GitHub Pages で公開する（追加費用なし）

1. GitHub でリポジトリの **Settings** → **Pages**
2. Source を **Deploy from a branch**
3. Branch を `claude/diagnosis-fortune-app-spec-r3rt91`、フォルダを **`/docs`** にして Save
4. 数分後、次のURLで開けるようになる

```
https://ichirou600-blip.github.io/body-color-diagnosis/privacy/
```

> **リポジトリが private の場合、GitHub Pages は有料プランが必要。**
> その場合は Google サイト、note、独自ドメインなど、
> **誰でもログインなしで開ける場所**ならどこでもよい。
> URLが変わったら、下の 5 で `PRIVACY_POLICY_URL` に指定する。

公開できたら、**スマホのブラウザでログインせずに開けること**を確認する。
審査ではここが実際に開かれる。

---

## 2. 楽天アフィリエイトIDを取得する

1. https://affiliate.rakuten.co.jp/ に楽天IDでログインして登録
2. 発行された**アフィリエイトID**を控える

> 楽天のアフィリエイトコードはリンクの種類によって値が変わる。
> 管理画面で実際に発行されるリンクと突き合わせて、
> `https://hb.afl.rakuten.co.jp/hgc/【ここ】/?pc=...` の部分を使うこと。

未取得のままでも、リンクは素の検索URLとして動く（収益が出ないだけ）。

---

## 3. AdMob の本番IDを用意する

`docs/STEP8_SETUP.md` を参照。控えるのは6つ。

- iOS / Android のアプリID → `Info.plist` と `AndroidManifest.xml` を直接書き換える
- iOS / Android のバナー・ネイティブのユニットID → 下の 5 で差し込む

---

## 4. Firebase を接続する

`docs/STEP6_SETUP.md` を参照。

**未設定でも審査には出せる。**その場合、占いは端末内の仮データのままになり、
毎日変わらない。「毎日開く理由」が売りなので、**リリース前には済ませたい。**

---

## 5. 本番IDをビルドに差し込む

`codemagic.yaml` は環境変数グループ `rakikara_release` から差し込む形にしてある。

### Codemagic に環境変数を追加する

Applications → body-color-diagnosis → **Environment variables** タブ

| Variable name | 値 | Secure |
|---|---|---|
| `RAKUTEN_AFFILIATE_ID` | 2 で取得したID | 任意 |
| `ADMOB_USE_PRODUCTION_IDS` | `true` | 不要 |
| `ADMOB_BANNER_UNIT_ID_IOS` | 3 のバナーID | 不要 |
| `ADMOB_NATIVE_UNIT_ID_IOS` | 3 のネイティブID | 不要 |
| `PRIVACY_POLICY_URL` | 1 で公開したURL | 不要 |

Variable group はすべて **`rakikara_release`** にする。

### codemagic.yaml の1行を有効にする

グループを作ったら、`codemagic.yaml` の以下のコメントを外す。

```yaml
        # - rakikara_release   ← この行の「# 」を消す
```

> **グループを作る前にコメントを外すとビルドが始まらない。**順番を守ること。

### 差し込めたかの確認

ビルド後、実機で確認する。

- 広告に「Test Ad」が**出なくなる**
- 「楽天でさがす」が `hb.afl.rakuten.co.jp` 経由で開く
- 「このアプリについて」→ プライバシーポリシーが 1 のURLで開く

---

## 6. スクリーンショットを用意する

```sh
flutter test tool/screenshots/screens_test.dart --update-goldens
```

`tool/screenshots/shots/` に **1290×2796**（iPhone 6.9インチ）で5枚出力される。
このサイズは Google Play の携帯電話用の要件も満たす。

載せる順番の案は `docs/STORE_LISTING.md` の末尾にある。

---

## 7. ストア情報を入力する

`docs/STORE_LISTING.md` に、そのまま貼れる文面をまとめてある。

- アプリ名、サブタイトル、説明、キーワード（**文字数は上限内に収めてある**）
- 年齢レーティングのアンケート回答
- Google Play のデータセーフティ回答
- カテゴリ

**注意点**

- カテゴリは「ライフスタイル」。**「子供向け」「ファミリー」には登録しない**（`docs/SPEC.md` §8）
- 年齢レーティングは、占いの項目があるため 12+ になる想定
- プライバシーポリシーURLは 1 のもの

---

## 8. リリースビルドを流して提出する

1. `codemagic.yaml` の `submit_to_app_store` を `true` にする（審査に出す指定）
2. 外部テスターにも配るなら、App Store Connect の TestFlight に
   **Beta App Description** を入れたうえで `submit_to_testflight` も `true` にする
3. Codemagic で `iOS - TestFlight` を実行
4. App Store Connect で内容を確認し、**審査に提出**

---

## 提出前チェックリスト

- [ ] プライバシーポリシーがログインなしで開ける
- [ ] アプリ内の「このアプリについて」からポリシーが開ける
- [ ] 広告に「Test Ad」が出ない
- [ ] 占いが当日の内容になっている（Firebase 接続済みの場合）
- [ ] スクリーンショットに広告が写り込んでいない
- [ ] 年齢レーティングを回答済み
- [ ] 「子供向け」カテゴリに登録していない
- [ ] 占いが娯楽目的である旨がアプリ内に出ている
- [ ] `flutter analyze` と `flutter test` が通っている
