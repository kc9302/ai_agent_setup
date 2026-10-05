// Render scenes.json to PNG frames with Playwright (Chromium).
// Usage: NODE_PATH=<dir containing playwright> node render.mjs scenes.json frames_dir
import { createRequire } from 'node:module';
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
const { chromium } = createRequire(import.meta.url)('playwright');

const [scenesPath, outDir] = process.argv.slice(2);
const scenes = JSON.parse(readFileSync(scenesPath, 'utf8'));
mkdirSync(outDir, { recursive: true });
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const css = `
body{margin:0;background:#0d1117;color:#c9d1d9;font:15px/1.45 'DejaVu Sans Mono',monospace}
.bar{background:#161b22;color:#8b949e;padding:10px 18px;border-bottom:1px solid #30363d;font-size:14px;display:flex;justify-content:space-between}
.bar b{color:#58a6ff;font-weight:600}
.term{padding:14px 18px;white-space:pre-wrap;word-break:break-word;height:482px;overflow:hidden;box-sizing:border-box}
.cmd{color:#7ee787}.dim{color:#8b949e}.out{color:#c9d1d9}.inj{color:#f2cc60}.bad{color:#ff7b72}.good{color:#7ee787}
.notice{color:#d2a8ff}.big{font-size:26px;color:#f0f6fc;margin:10px 0}.final .term{display:flex;flex-direction:column;justify-content:center}
.cur{display:inline-block;width:8px;height:15px;background:#c9d1d9;vertical-align:-2px}`;
const html = (scene, n) => `<html><head><style>${css}</style></head><body class="${scene.final ? 'final' : ''}">
<div class="bar"><b>${esc(scene.title)}</b><span>${scene.final ? '' : 'replay of examples/scooter (real script output)'}</span></div>
<div class="term">${scene.lines.slice(0, n).map(([c, t]) => `<div class="${c}">${esc(t)}</div>`).join('')}<span class="cur"></span></div></body></html>`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 960, height: 520 } });
const frames = [];
let k = 0;
for (const scene of scenes) {
  for (let n = 1; n <= scene.lines.length; n++) {
    await page.setContent(html(scene, n));
    const f = `${outDir}/f${String(k++).padStart(4, '0')}.png`;
    await page.screenshot({ path: f });
    const last = n === scene.lines.length;
    const isCmd = scene.lines[n - 1][0] === 'cmd';
    frames.push({ f, d: last ? (scene.final ? 4.5 : 3.2) : isCmd ? 0.9 : 0.35 });
  }
}
await browser.close();
// ffmpeg concat list with per-frame durations
let list = frames.map(({ f, d }) => `file '${f}'\nduration ${d}`).join('\n');
list += `\nfile '${frames.at(-1).f}'\n`;
writeFileSync(`${outDir}/list.txt`, list);
console.log(frames.length, 'frames');
