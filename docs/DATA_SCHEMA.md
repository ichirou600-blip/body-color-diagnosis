# 静的コンテンツ JSON スキーマ（`assets/`）

`docs/SPEC.md` §5 の静的JSONの、具体的なキー名と値の取り決め。
**コンテンツ本体はチャット側で作成する**（`CLAUDE.md`）。このファイルは「どういう形で渡せばコードがそのまま読めるか」の契約。

現在 `assets/` に入っているのは **構造確認用の仮データ**。各ファイルの `_note` に仮である旨を書いてある。
本データができたら、同じ形のまま丸ごと差し替えればコード変更は不要。

## 共通のID語彙

コード側の enum と1対1で対応する。**この文字列は変えないこと。**

| 区分 | id | 表示名 |
|---|---|---|
| パーソナルカラー | `spring` / `summer` / `autumn` / `winter` | イエベ春 / ブルベ夏 / イエベ秋 / ブルベ冬 |
| 骨格 | `straight` / `wave` / `natural` | ストレート / ウェーブ / ナチュラル |
| 星座 | `aries` `taurus` `gemini` `cancer` `leo` `virgo` `libra` `scorpio` `sagittarius` `capricorn` `aquarius` `pisces` | 牡羊座 … 魚座 |

全ファイル共通で `version`（整数）と `_note`（任意の覚え書き・省略可）を持つ。

## `color_master.json` — 色マスタ（本データは40色）

```json
{
  "version": 1,
  "colors": [
    { "id": "coral_pink", "name": "コーラルピンク", "hex": "#FF8B7B", "pc_types": ["spring"] }
  ]
}
```

- `id`: 半角英小文字とアンダースコアのみ。**他ファイルからこのidで参照する**ので、後から変えない
- `hex`: `#RRGGBB` の7文字
- `pc_types`: その色が似合うPCタイプ。複数可・空配列も可

## `type_attributes.json` — タイプ属性（PC4種＋骨格3種）

```json
{
  "version": 1,
  "personal_colors": [
    {
      "id": "spring",
      "color_ids": ["coral_pink"],
      "materials": ["ツヤのある素材"],
      "keywords": ["明るい", "クリア"],
      "description": "…"
    }
  ],
  "kokkaku": [
    {
      "id": "straight",
      "color_ids": [],
      "materials": ["ハリのある素材"],
      "keywords": ["シンプル"],
      "description": "…"
    }
  ]
}
```

- `personal_colors` は4件、`kokkaku` は3件ちょうど
- `color_ids` は `color_master.json` に実在するidのみ。骨格側は色と無関係なので空配列でよい
- `description` は**「似合うものの提案」だけを書く**。体型のネガティブ言及・ダイエット誘導・容姿の優劣は禁止（`docs/SPEC.md` §8）

## `pc_x_kokkaku.json` — PC×骨格（4×3 = 12件）

```json
{
  "version": 1,
  "entries": [
    { "pc_type": "spring", "kokkaku_type": "straight", "style_text": "…" }
  ]
}
```

- 12通りすべて必要。重複不可

## `compatibility.json` — 星座相性（78件）

```json
{
  "version": 1,
  "entries": [
    { "zodiac_a": "aries", "zodiac_b": "taurus", "text": "…" }
  ]
}
```

- **順序なしのペア**。`(aries, taurus)` と `(taurus, aries)` は同じ1件で、どちらの向きで書いても読める
- 同じ星座同士（`aries` × `aries`）も1件として含む
- したがって 12×13÷2 = **78件**

## `questions.json` — 診断質問（PC10問＋骨格10問）

```json
{
  "version": 1,
  "personal_color": [
    {
      "id": "pc_q01",
      "text": "手首の血管の色に近いのは？",
      "choices": [
        { "id": "a", "text": "緑っぽい", "scores": { "spring": 1, "autumn": 1 } },
        { "id": "b", "text": "青っぽい", "scores": { "summer": 1, "winter": 1 } }
      ]
    }
  ],
  "kokkaku": [
    {
      "id": "kk_q01",
      "text": "…",
      "choices": [
        { "id": "a", "text": "…", "scores": { "straight": 1 } }
      ]
    }
  ]
}
```

- `personal_color` は10問、`kokkaku` は10問
- `scores` のキーは、そのセクションのタイプid（PCなら `spring`〜`winter`、骨格なら `straight`〜`natural`）。**0点のタイプはキーごと省略してよい**

### パーソナルカラーの判定は2軸方式

4分類は独立した4タイプではなく、2つの軸の交点。判定もそのように行う（`lib/logic/personal_color_judge.dart`）。

| 軸 | 一方 | もう一方 |
|---|---|---|
| 暖寒軸 | イエベ = `spring` + `autumn` | ブルベ = `summer` + `winter` |
| 明深軸 | 明るく澄んだ = `spring` + `summer` | 深い = `autumn` + `winter` |

タイプ合計の最大値を採る方式だと、弱い手がかりが積み重なって決定的な手がかりを打ち消し、同点も頻発する（この方式での実測は全回答パターンの18.4%が同点）。軸ごとに証拠をまとめてから交点を採ると、その両方が解消する。

**配点を書くときのルール（守らないと同点が復活する）**

1. **同じ設問のどの選択肢を選んでも、配点の合計を同じにする**
   例: ある設問の合計を3点にすると決めたら、全選択肢が合計3点（`{"spring":2,"autumn":1}` も `{"summer":3}` も合計3）
2. **全10問の合計点を奇数にする**（現在は21点）

この2つが揃うと「暖＝寒」「明＝深」が算術的に起こりえなくなり、同点がゼロになる。
`test/assets_judgement_test.dart` がこの性質と、全786,432通りの回答パターンでの同点ゼロ・4タイプ均等分布を検証する。

### 骨格の判定はタイプ合計方式

骨格3分類は2軸に分解できないので、合計点が最大のタイプを採る。同点の場合は上の「共通のID語彙」の並び順で先にあるほうを採用する。

同点を完全には消せないため、**設問ごとの重みで同点率を下げてある**（決定的な設問ほど重く。実測 0.79%）。重みを変えるときは `test/assets_judgement_test.dart` が同点率2%未満と分布の均等さを検証するので、そこで気づける。

## コードが起動時に検証すること

`MasterRepository.load()` が以下を満たさない場合は例外を投げる。本データを入れたときにここで落ちたら、JSON側の不備。

1. 各ファイルの必須キーが揃っていて、型が正しい
2. ID語彙が未知の値でない（例: `pc_types` に `spring2` のような値がない）
3. `type_attributes.json` の `color_ids` が `color_master.json` に実在する
4. `personal_colors` 4件・`kokkaku` 3件ちょうど
5. `pc_x_kokkaku.json` のペアに重複がない
6. `compatibility.json` のペアに重複がない（順序を無視して判定）
7. `questions.json` の各問に選択肢が2つ以上あり、`scores` のキーがそのセクションの語彙に収まっている

**件数（40色 / 12通り / 78件 / 各10問）は起動時には検証しない。**仮データでも動くようにするため。
件数と文言ルールは `test/assets_completeness_test.dart` で検証する。
