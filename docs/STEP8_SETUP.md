# Step 8 セットアップ手順（広告の本番ID差し替え）

`docs/SPEC.md` §9 Step 8 の完了条件は **「バナー・ネイティブが表示される」**。
コード側は完了していて、いまは **Google 公式のテスト用IDで動く**。
実機で広告枠が出ることはこの状態で確認できる（テスト広告は「Test Ad」と表示される）。

本番の広告を出すには AdMob 側の登録が要る。以下はその手順。

## いまの状態

| 項目 | 状態 |
|---|---|
| バナー | 全画面の下部に常設。アダプティブサイズ |
| ネイティブ | PC診断結果・骨格診断結果・今日のおすすめ の3画面 |
| リワード | 未実装（`docs/SPEC.md` §4 で P1） |
| 広告ID | Google 公式のテスト用ID |
| パーソナライズ | **無効（NPA 固定）** |
| ATT プロンプト | **出さない** |
| 未成年配慮 | `AgeRestrictedTreatment.teen` ＋ `maxAdContentRating: T` |

広告の読み込みに失敗しても、広告ウィジェットは高さ0で何も描かない。
「枠だけ空いている」状態にはならない。

## 発行済みのID

パブリッシャーID: `pub-4074648031071093`

| 種類 | ID |
|---|---|
| iOS アプリID | `ca-app-pub-4074648031071093~4534112070` |
| iOS バナー | `ca-app-pub-4074648031071093/8402923520` |
| iOS ネイティブ | `ca-app-pub-4074648031071093/7262443693` |
| Android アプリID | `ca-app-pub-4074648031071093~8566575053` |
| Android バナー | `ca-app-pub-4074648031071093/8493538384` |
| Android ネイティブ | `ca-app-pub-4074648031071093/9615048360` |

アプリIDは `Info.plist` / `AndroidManifest.xml` に反映済み。
ユニットIDは Codemagic の `rakikara_release` グループから `--dart-define` で渡す。

> AdMob アカウントは審査待ち（お支払い方法が未登録）。
> 承認されるまで本番広告は配信されず、広告枠は高さ0のまま描かれない。

---

<details><summary>登録時の手順（記録用）</summary>

## 1. AdMob にアプリを登録する

1. [AdMob](https://apps.admob.com/) でアカウントを作成
2. アプリを2つ登録する（iOS と Android は別アプリ扱い）
   - まだストア公開前なので「いいえ、ストアに登録されていません」を選ぶ
   - アプリ名: ラキカラ
3. それぞれで **広告ユニットを2つずつ**作る
   - バナー
   - ネイティブアドバンス

控える値は6つ。

| 値 | 使い道 |
|---|---|
| iOS のアプリID（`ca-app-pub-xxxx~yyyy`） | `ios/Runner/Info.plist` |
| Android のアプリID（`ca-app-pub-xxxx~yyyy`） | `android/app/src/main/AndroidManifest.xml` |
| iOS バナーのユニットID（`ca-app-pub-xxxx/yyyy`） | `--dart-define` |
| iOS ネイティブのユニットID | `--dart-define` |
| Android バナーのユニットID | `--dart-define` |
| Android ネイティブのユニットID | `--dart-define` |

> アプリIDは `~`、ユニットIDは `/` で区切られる。混同しやすいので注意。

</details>

## 2. 未成年向けの設定を AdMob 側でも入れる

アプリ内のコードだけでなく、AdMob の管理画面側にも設定がある。

- 各アプリの設定で **「ユーザー同意年齢未満（TFUA）」** の扱いを確認する
- **「子ども向け（COPPA / TFCD）」は有効にしない**。対象は13歳以上で、
  ストアの子供向けカテゴリにも登録しない（`docs/SPEC.md` §8）

## 3. アプリIDを差し替える

ユニットIDと違い、アプリIDは `--dart-define` では渡せない。以下2ファイルを直接書き換える。

- `ios/Runner/Info.plist` の `GADApplicationIdentifier`
- `android/app/src/main/AndroidManifest.xml` の `com.google.android.gms.ads.APPLICATION_ID`

いまはどちらも Google 公式のテスト用IDが入っている。

## 4. ユニットIDをビルド時に差し込む

```sh
flutter build ipa --release \
  --dart-define=ADMOB_USE_PRODUCTION_IDS=true \
  --dart-define=ADMOB_BANNER_UNIT_ID_IOS=ca-app-pub-xxxx/yyyy \
  --dart-define=ADMOB_NATIVE_UNIT_ID_IOS=ca-app-pub-xxxx/zzzz
```

Codemagic では `codemagic.yaml` の `Build ipa` に同じ `--dart-define` を足すか、
環境変数グループに入れて参照する。

**`ADMOB_USE_PRODUCTION_IDS=true` を渡してもユニットIDが渡っていない場合は、
テストIDで動く。**空のユニットIDで読み込みに行っても失敗するだけなので、
テストIDで動いて気づけるようにしてある（`AdConfig.usingTestIds`）。

## 5. 確認

- 実機で下部にバナーが出る
- 診断結果・今日のおすすめにネイティブ広告が出る
- テストIDのままなら広告に「Test Ad」と表示される。本番IDなら表示されない

## 設計上の決めごと

### 非パーソナライズ広告（NPA）を固定にしている

`lib/ads/ads_bootstrap.dart` の `kAdRequest` が `nonPersonalizedAds: true` を持ち、
すべての広告リクエストがこれを使う。切り替えUIは設けていない。
主対象が未成年なので、パーソナライズ広告を出さないことで審査・法務リスクを下げる
（`docs/SPEC.md` §2）。eCPM は下がるが、これは意図した判断。

### ATT を出さない

非パーソナライズ広告しか出さないため、トラッキング許可を求める理由がない。
`Info.plist` に `NSUserTrackingUsageDescription` を**入れない**ことで、
プロンプトを出せない状態にしてある。

この2点は `test/ads_policy_test.dart` が検証する。あとから1行足して崩れないようにするため。

### 診断の質問画面の広告

質問画面は選択肢を連打する画面なので、下端の広告と隣接させないよう余白を入れている。
誤タップは AdMob の無効トラフィック（アカウント停止の理由になりうる）につながる。

### 同意管理（UMP / GDPR）

日本国内向けのみであれば、いまの構成で足りる。
EEA / 英国のユーザーにも配信する場合は、AdMob の UMP SDK による同意取得が別途必要になる。
その場合も NPA 固定の方針は変えない。
