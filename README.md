# ラキカラ

パーソナルカラー・骨格・星座の「タイプ」と、毎日変わる占いを掛け合わせて、
その日のコーデ・ネイル・ヘアアクセを提案する iOS / Android アプリ。

## ドキュメント

| ファイル | 内容 |
|---|---|
| [`docs/SPEC.md`](docs/SPEC.md) | 要件定義書・実装計画書 v1。**実装判断はすべてここに従う** |
| [`docs/STEP0_SETUP.md`](docs/STEP0_SETUP.md) | Codemagic → TestFlight を通すための Apple / Codemagic 側の手順 |
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

`docs/SPEC.md` §9 のステップを順に進める。現在は **Step 0**（ビルド・配信パイプラインの貫通）。
