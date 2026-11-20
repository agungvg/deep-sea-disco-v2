// Render screenshots for Deep Sea Disco v2 with headless Chromium, then quantize to <256 KiB PNG.
import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const dir = dirname(fileURLToPath(import.meta.url));
const CHROME = resolve(process.env.HOME, ".cache/ms-playwright/chromium-1255/chrome-linux64/chrome");
const shots = [
  ["cover", "1-cover.png"],
  ["gameplay", "2-gameplay.png"],
  ["base", "3-base.png"],
  ["event", "4-event.png"],
];

for (const [scene, out] of shots) {
  const target = resolve(dir, "..", "screenshots", out);
  execFileSync(CHROME, [
    "--headless=new",
    "--disable-gpu",
    "--no-sandbox",
    `--window-size=1024,576`,
    `--screenshot=${target}`,
    `file://${resolve(dir, "scene.html")}?s=${scene}`,
  ], { stdio: "inherit" });
  console.log("shot:", out, existsSync(target) ? "written" : "MISSING");
}

// Quantize each PNG to a 256-color adaptive palette so it fits the 256 KiB kit cap.
const py = `
import sys
from PIL import Image
for path in sys.argv[1:]:
    im = Image.open(path).convert("RGB")
    q = im.quantize(colors=256, method=Image.MEDIANCUT)
    q.save(path, optimize=True)
    import os
    print(path, os.path.getsize(path), "bytes")
`;
const { writeFileSync } = await import("node:fs");
writeFileSync("/tmp/quantize_shots.py", py);
const { spawnSync } = await import("node:child_process");
const files = shots.map(([, out]) => resolve(dir, "..", "screenshots", out));
const r = spawnSync("python3", ["/tmp/quantize_shots.py", ...files], { stdio: "inherit" });
if (r.status !== 0) process.exit(r.status);
console.log("done");
