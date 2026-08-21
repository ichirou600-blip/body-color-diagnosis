import Anthropic from "@anthropic-ai/sdk";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions";

import {
  generateFortune,
  ZODIAC_IDS,
  ZODIAC_LABELS,
  type ZodiacId,
} from "./fortune.js";

/**
 * Claude API キー。
 *
 * **アプリ側には絶対に置かない**（`CLAUDE.md` の「絶対に破らないルール」2）。
 * Secret Manager に入れて、この関数の実行時にだけ渡す:
 *   firebase functions:secrets:set ANTHROPIC_API_KEY
 */
const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

if (getApps().length === 0) {
  initializeApp();
}

/** JST の「今日」を YYYY-MM-DD で返す。Firestore のドキュメントIDに使う。 */
function todayInJst(now: Date): string {
  const jst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return jst.toISOString().slice(0, 10);
}

/**
 * 毎朝5:00 JST に12星座ぶんの占いを生成して Firestore に書く。
 *
 * 保存先は `daily_fortune/{YYYY-MM-DD}/zodiacs/{zodiacId}`。
 * `docs/SPEC.md` §5 は `daily_fortune/{date}/{zodiac}` と書いているが、
 * Firestore のパスはコレクションとドキュメントが交互でなければならないため
 * `zodiacs` を挟んでいる。意味は同じ。
 *
 * **ユーザー個人のデータはここには一切入らない。**星座単位の共有データだけ。
 */
export const generateDailyFortunes = onSchedule(
  {
    schedule: "0 5 * * *",
    timeZone: "Asia/Tokyo",
    secrets: [anthropicApiKey],
    region: "asia-northeast1",
    // 12回の逐次呼び出しに十分な余裕を持たせる
    timeoutSeconds: 540,
    retryCount: 3,
  },
  async (event) => {
    const date = todayInJst(new Date(event.scheduleTime ?? Date.now()));
    const client = new Anthropic({ apiKey: anthropicApiKey.value() });
    const firestore = getFirestore();
    const collection = firestore
      .collection("daily_fortune")
      .doc(date)
      .collection("zodiacs");

    const failed: ZodiacId[] = [];

    // 並列にするとレート制限に当たりうるうえ、1日12回なので逐次で十分。
    for (const zodiac of ZODIAC_IDS) {
      try {
        const fortune = await generateFortune(
          client,
          ZODIAC_LABELS[zodiac],
          date,
        );
        await collection.doc(zodiac).set({
          ...fortune,
          zodiac,
          date,
          generated_at: new Date().toISOString(),
        });
        logger.info(`generated ${date} ${zodiac}`, {
          lucky_color_id: fortune.lucky_color_id,
        });
      } catch (error) {
        // 1星座失敗しても残りは書く。全滅させない。
        failed.push(zodiac);
        logger.error(`failed ${date} ${zodiac}`, error);
      }
    }

    if (failed.length > 0) {
      // 再実行で埋められるように、失敗があれば関数自体を失敗扱いにする
      throw new Error(`生成に失敗した星座: ${failed.join(", ")}`);
    }
  },
);
