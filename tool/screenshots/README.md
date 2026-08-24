# 画面のスクリーンショット生成

実機やシミュレータなしでデザインを確認するための仕組み。
`flutter test` の既定対象は `test/` なので、**CI では走らない。**

```sh
flutter test tool/screenshots/screens_test.dart --update-goldens
```

`tool/screenshots/shots/` に PNG が出力される。

- 同梱フォント（M PLUS Rounded 1c）とアイコンフォントを読み込んでから描画するので、
  実機に近い見た目になる
- 絵文字はテスト環境にフォントが無いため描画されない。実機では出る
- 出力した PNG はコミットしない（`.gitignore` 済み）
