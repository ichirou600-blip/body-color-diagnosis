# ラキカラ

パーソナルカラー・骨格・星座の「タイプ」と、毎日変わる占いを掛け合わせて、
その日のコーデ・ネイル・ヘアアクセを提案する iOS / Android アプリ。

## ドキュメント

| ファイル | 内容 |
|---|---|
| [`docs/SPEC.md`](docs/SPEC.md) | 要件定義書・実装計画書 v1。**実装判断はすべてここに従う** |
| [`docs/TESTFLIGHT_CHECKLIST.md`](docs/TESTFLIGHT_CHECKLIST.md) | 実機で確認するまでの手順と確認項目（初回は完了済み） |
| [`docs/STEP0_SETUP.md`](docs/STEP0_SETUP.md) | Codemagic → TestFlight を通すための Apple / Codemagic 側の手順 |
| [`docs/DATA_SCHEMA.md`](docs/DATA_SCHEMA.md) | `assets/` の静的JSONのキー名と検証ルール |
| [`docs/STEP6_SETUP.md`](docs/STEP6_SETUP.md) | Firebase 接続と占い生成バッチのデプロイ手順 |
| [`docs/STEP8_SETUP.md`](docs/STEP8_SETUP.md) | AdMob 登録と広告の本番ID差し替え手順 |
| [`CLAUDE.md`](CLAUDE.md) | Claude Code 向けの作業ルール |

## 開発

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Cloud Functions（占いの生成バッチ）:

```sh
cd functions
npm install
npm run typecheck
```

Flutter 3.47.0（CI で固定）。

## 進捗

`docs/SPEC.md` §9 のステップを順に進める。

| Step | 状態 |
|---|---|
| 0 ビルド・配信パイプライン | コード側完了。Apple / Codemagic 側の操作待ち |
| 1 静的JSON読込＋プロフィール保存 | 完了 |
| 2 PC診断フロー | 完了 |
| 3 骨格診断＋PC×骨格の結果表示 | 完了 |
| 4 シェア画像生成 | 完了 |
| 5 掛け合わせエンジン＋今日のおすすめ | 完了（占いは端末内の仮データ。Step 6 で Firestore 配信に差し替え） |
| 6 Firebase接続＋Functionsバッチ | コード側完了。Firebase / Anthropic 側の設定待ち |
| 7 相性診断 | 完了 |
| 8 広告組込 | コード側完了。テストIDで動作中。本番IDは AdMob 登録後に差し替え |
| 9 アフィリリンク・ポリシー・ストア素材・審査提出 | 未着手 |

TestFlight での実機確認は完了。アイコンと画面デザインも刷新済み。

静的コンテンツ（色マスタ40色・診断20問・タイプ属性・PC×骨格12通り・星座相性78件）は投入済み。
