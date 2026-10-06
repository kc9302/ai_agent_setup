#!/usr/bin/env node
// bash 없이 스킬만 설치한다 (Windows PowerShell 등). 도구(manifest/tools.list)는 설치하지 않는다.
//   node scripts/install-skills.mjs [--dry-run] [--project] [--agent <이름>]... [--tag <태그>]
// bootstrap.sh 의 스킬 단계와 같은 규칙: manifest/skills.list 의 모든 소스(커밋 고정) +
// 이 저장소의 skills/ 폴더(로컬 스킬)를 설치하고, 끝나면 이름이 실제로 설치됐는지 확인한다.
// 필요한 것: Node.js 18+ (npx).
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const argv = process.argv.slice(2);
let dryRun = false, scope = '-g', tag = '';
const agents = [];
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--dry-run') dryRun = true;
  else if (a === '--project') scope = '';
  else if (a === '--global' || a === '-g') scope = '-g';
  else if (a === '--agent' || a === '-a') agents.push(argv[++i]);
  else if (a === '--tag') tag = argv[++i] || '';
  else if (a === '-h' || a === '--help') { console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').slice(1, 6).map((l) => l.replace(/^\/\/ ?/, '')).join('\n')); process.exit(0); }
  else { console.error(`알 수 없는 옵션: ${a}`); process.exit(2); }
}

const win = process.platform === 'win32';
const q = (s) => (win && /[^\w@.:/\\#=,-]/.test(s) ? `"${s}"` : s);
function npx(args, { capture = false } = {}) {
  const full = ['-y', ...args];
  console.log('$ npx ' + full.map(q).join(' '));
  if (dryRun && !capture) return { status: 0 };
  return spawnSync('npx', win ? full.map(q) : full, { shell: win, encoding: 'utf8', stdio: capture ? ['ignore', 'pipe', 'pipe'] : 'inherit' });
}

// manifest/skills.list 한 줄을 필드로 나눈다. `\|` 는 글자 '|' (lib.sh 의 split_fields 와 같다).
function fields(line) {
  const s = line.replaceAll('\\|', '\x01').replaceAll('||', '\x02');
  return s.split('|').map((f) => f.replaceAll('\x01', '|').replaceAll('\x02', '||').trim());
}
const hasTag = (tags, t) => !t || tags.split(',').map((x) => x.trim()).includes(t);
const agentFlags = agents.flatMap((a) => ['-a', a.trim()]);

const failed = [], expectNames = [], expectSources = [];
console.log('==> manifest/skills.list 의 스킬 설치');
for (const raw of readFileSync(join(root, 'manifest', 'skills.list'), 'utf8').split(/\r?\n/)) {
  const line = raw.trim();
  if (!line || line.startsWith('#')) continue;
  const [src, skillsField = '*', tags = ''] = fields(line);
  if (!hasTag(tags, tag)) continue;
  const repo = src.split('#')[0];
  const args = ['skills', 'add', src, '-y'];
  if (scope) args.push(scope);
  args.push(...agentFlags);
  if (tags.split(',').map((x) => x.trim()).includes('full-depth')) args.push('--full-depth');
  const names = skillsField === '*' ? ['*'] : skillsField.split(',').map((x) => x.trim()).filter(Boolean);
  for (const n of names) args.push('--skill', n);
  const r = npx(args);
  if (r.status !== 0) failed.push(`skill:${src}`);
  else if (names[0] === '*') expectSources.push(repo);
  else for (const n of names) expectNames.push(n);
}

// 이 저장소가 직접 정의한 스킬(skills/). 표만 보고 설치하면 빠지는 부분이다.
if (!tag || tag === 'local') {
  const localNames = [];
  const dir = join(root, 'skills');
  if (existsSync(dir)) {
    for (const d of readdirSync(dir, { withFileTypes: true })) {
      const f = join(dir, d.name, 'SKILL.md');
      if (!d.isDirectory() || !existsSync(f)) continue;
      const m = readFileSync(f, 'utf8').match(/^name:\s*["']?([^"'\r\n]+?)["']?\s*$/m);
      if (m) localNames.push(m[1]);
    }
  }
  if (localNames.length) {
    console.log(`==> 이 저장소의 로컬 스킬 (skills/): ${localNames.join(', ')}`);
    const args = ['skills', 'add', root, '-y'];
    if (scope) args.push(scope);
    args.push(...agentFlags);
    for (const n of localNames) args.push('--skill', n);
    if (npx(args).status !== 0) failed.push('skill:local');
    else expectNames.push(...localNames);
  }
}

// 설치 명령이 성공해도 일부가 조용히 빠질 수 있으므로 이름으로 확인한다.
if (!dryRun && (expectNames.length || expectSources.length)) {
  console.log('==> 설치 확인');
  const lsArgs = ['skills', 'ls', '--json'];
  if (scope) lsArgs.push(scope);
  for (const a of (agents.length ? agents : [''])) {
    const r = npx([...lsArgs, ...(a ? ['-a', a] : [])], { capture: true });
    let rows;
    try { rows = JSON.parse(r.stdout.slice(r.stdout.indexOf('['))); } catch { console.warn('설치 결과를 확인하지 못했습니다 (skills ls --json 해석 실패)'); rows = null; }
    if (!rows) continue;
    const have = new Set(rows.map((x) => x.name));
    const srcs = new Set(rows.map((x) => (x.source || '').toLowerCase()));
    for (const n of expectNames) if (!have.has(n)) failed.push(`skill-missing: ${n}`);
    for (const s of expectSources) if (!srcs.has(s.toLowerCase())) failed.push(`skill-missing: (설치된 스킬 없음) ← ${s}`);
    if (![...failed].some((f) => f.startsWith('skill-missing'))) console.log(`  ✓ 이름으로 지정한 스킬 ${expectNames.length}개, 와일드카드 소스 ${expectSources.length}개 모두 설치됨`);
  }
}

console.log('');
if (failed.length) { console.error(`실패 ${failed.length}건:\n  - ${failed.join('\n  - ')}`); process.exit(1); }
console.log(dryRun ? '==> dry-run 끝 (설치하지 않음)' : '==> 끝. Claude Code 등은 새 세션으로 다시 열어야 새 스킬이 보입니다.');
