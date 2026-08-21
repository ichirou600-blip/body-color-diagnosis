// assets/color_master.json から src/colorIds.ts を生成する。
//
// 生成AIに選ばせる色IDは、アプリが持つ色マスタと完全に一致していなければ
// 「配信された色がアプリに存在しない」という壊れ方をする。手で写さない。
//
//   npm run sync-color-ids
//
// ズレていないかは test/functions_color_ids_test.dart が CI で検証する。
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(here, "..", "..");

const master = JSON.parse(
  readFileSync(join(repoRoot, "assets", "color_master.json"), "utf8"),
);
const ids = master.colors.map((color) => color.id);

const body = `// 自動生成ファイル。直接編集しない。
// 生成元: assets/color_master.json
// 再生成: npm run sync-color-ids
export const COLOR_IDS = [
${ids.map((id) => `  ${JSON.stringify(id)},`).join("\n")}
] as const;
`;

writeFileSync(join(here, "..", "src", "colorIds.ts"), body);
console.log(`wrote ${ids.length} color ids`);
