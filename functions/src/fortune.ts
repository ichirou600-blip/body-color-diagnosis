import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { z } from "zod";

import { COLOR_IDS } from "./colorIds.js";

/// 星座ID。アプリ側 `lib/models/enums.dart` の Zodiac と一致させる。
export const ZODIAC_IDS = [
  "aries",
  "taurus",
  "gemini",
  "cancer",
  "leo",
  "virgo",
  "libra",
  "scorpio",
  "sagittarius",
  "capricorn",
  "aquarius",
  "pisces",
] as const;

export type ZodiacId = (typeof ZODIAC_IDS)[number];

/// アプリ側 `lib/models/daily_fortune.dart` の ItemCategory と一致させる。
export const ITEM_CATEGORY_IDS = ["outfit", "nail", "hair_accessory"] as const;

/**
 * 生成させるJSONの形。
 *
 * lucky_color_id と lucky_item_category を enum に固定するのが要点。
 * 自由生成させると、アプリに存在しない色が配信されて掛け合わせが壊れる
 * （`docs/SPEC.md` §7）。
 */
export const FortuneSchema = z.object({
  message: z
    .string()
    .describe("その日の運勢文。60〜100文字程度の日本語。"),
  lucky_color_id: z.enum(COLOR_IDS).describe("ラッキーカラーの色ID。"),
  lucky_item_category: z
    .enum(ITEM_CATEGORY_IDS)
    .describe("その日に力を入れるとよいアイテムのカテゴリ。"),
});

export type Fortune = z.infer<typeof FortuneSchema>;

/** SPEC §7 の方針どおり軽量モデルを使う。1日12呼び出しなのでコストはほぼゼロ。 */
export const MODEL_ID = "claude-haiku-4-5";

const SYSTEM_PROMPT = `あなたは日本の女子高生向け占いアプリ「ラキカラ」の占い文を書くライターです。

書き方のルール:
- 読者は13〜18歳の女の子。丁寧すぎず、ギャル語にも寄せない言葉づかいにする
- 断定しない。「〜かも」「〜そう」「〜なはず」のようなやわらかい語尾を混ぜる
- その日の行動のヒントが1つ入っていると読み応えが出る
- 学校・友達・部活・放課後といった、読者の生活に近い場面を使う

絶対に書いてはいけないこと:
- 体型・容姿への言及、ダイエットや痩せる/太ることに関する言及
- 容姿の優劣を示す表現
- 不安をあおる表現、健康・進路・金銭についての断定的な予言
- 恋愛の断定（「絶対に付き合える」など）

出力は指定されたJSONスキーマのみ。説明文や前置きは書かないこと。`;

/**
 * 1星座ぶんの占いを生成する。
 *
 * 構造化出力（`output_config.format`）でスキーマを強制するので、
 * 返ってきたJSONをこちら側でパースし直す必要はない。
 */
export async function generateFortune(
  client: Anthropic,
  zodiacLabel: string,
  dateLabel: string,
): Promise<Fortune> {
  const response = await client.messages.parse({
    model: MODEL_ID,
    max_tokens: 1024,
    system: SYSTEM_PROMPT,
    messages: [
      {
        role: "user",
        content: `${dateLabel}の${zodiacLabel}の運勢を書いてください。`,
      },
    ],
    output_config: { format: zodOutputFormat(FortuneSchema) },
  });

  const parsed = response.parsed_output;
  if (parsed == null) {
    throw new Error(`${zodiacLabel}: スキーマに沿った出力を得られませんでした`);
  }
  return parsed;
}

/** 表示用の星座名。運勢文の生成プロンプトに使う。 */
export const ZODIAC_LABELS: Record<ZodiacId, string> = {
  aries: "牡羊座",
  taurus: "牡牛座",
  gemini: "双子座",
  cancer: "蟹座",
  leo: "獅子座",
  virgo: "乙女座",
  libra: "天秤座",
  scorpio: "蠍座",
  sagittarius: "射手座",
  capricorn: "山羊座",
  aquarius: "水瓶座",
  pisces: "魚座",
};
