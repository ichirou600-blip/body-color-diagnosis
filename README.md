# ラキカラ

パーソナルカラー・骨格・星座の「タイプ」と、毎日変わる占いを掛け合わせて、
その日のコーデ・ネイル・ヘアアクセを提案する iOS / Android アプリ。

## ドキュメント

| ファイル | 内容 |
|---|---|
| [`docs/SPEC.md`](docs/SPEC.md) | 要件定義書・実装計画書 v1。**実装判断はすべてここに従う** |
| [`docs/STEP0_SETUP.md`](docs/STEP0_SETUP.md) | Codemagic → TestFlight を通すための Apple / Codemagic 側の手順 |
| [`docs/DATA_SCHEMA.md`](docs/DATA_SCHEMA.md) | `assets/` の静的JSONのキー名と検証ルール |
| [`CLAUDE.md`](CLAUDE.md) | Claude Code 向けの作業ルール |

## 開発

```sh
flutter pub get
flutter analyze
flutter test
flutter run
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

静的コンテンツ（色マスタ40色・診断20問・タイプ属性・PC×骨格12通り・星座相性78件）は投入済み。
