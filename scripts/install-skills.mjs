#!/usr/bin/env node
// bash 없이 스킬만 설치한다 (Windows PowerShell 등). 도구(manifest/tools.list)는 설치하지 않는다.
//   node scripts/install-skills.mjs [--dry-run] [--project] [--agent <이름>]... [--tag <태그>] [--profile minimal|full] [--diff] [--wsl]
//   --profile minimal : core 태그 스킬만(로컬 스킬 제외). 도구는 원래 설치하지 않는다.
//   --diff            : 설치하지 않고, 이미 설치된 스킬과 겹치는(덮어쓸) 것을 미리 보여준다.
// bootstrap.sh 의 스킬 단계와 같은 규칙: manifest/skills.list 의 모든 소스(커밋 고정) +
// 이 저장소의 skills/ 폴더(로컬 스킬)를 설치하고, 끝나면 이름이 실제로 설치됐는지 확인한다.
// 필요한 것: Node.js 22.20+ (npx), git. 낮은 Node 에서는 skills CLI 의 최신판을 받지 못한다(아래 사전 점검 참고).
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { homedir, platform } from 'node:os';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const argv = process.argv.slice(2);
let dryRun = false, diffMode = false, profile = 'full', scope = '-g', tag = '', allowWsl = process.env.AI_SETUP_ALLOW_WSL === '1';
const agents = [];
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--dry-run') dryRun = true;
  else if (a === '--project') scope = '';
  else if (a === '--global' || a === '-g') scope = '-g';
  else if (a === '--agent' || a === '-a') agents.push(argv[++i]);
  else if (a === '--tag') tag = argv[++i] || '';
  else if (a === '--wsl') allowWsl = true;
  else if (a === '--diff') { diffMode = true; dryRun = true; }
  else if (a === '--profile') profile = argv[++i] || '';
  else if (a === '-h' || a === '--help') { console.log(readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').slice(1, 6).map((l) => l.replace(/^\/\/ ?/, '')).join('\n')); process.exit(0); }
  else { console.error(`알 수 없는 옵션: ${a}`); process.exit(2); }
}

if (profile === 'minimal') {
  if (tag) { console.error('[error] --profile minimal 은 --tag 와 함께 쓸 수 없습니다 (minimal 은 core 태그)'); process.exit(2); }
  tag = 'core';
} else if (profile !== 'full') { console.error(`[error] 알 수 없는 프로필: ${profile || '(빈 값)'} (full | minimal)`); process.exit(2); }

// skills CLI 가 스킬을 받을 때 쓰는 git 이 줄바꿈을 바꾸지 않게 한다. Windows 의 Git 기본값(core.autocrlf=true)이면 받은 스킬의 텍스트 파일이 CRLF 가 되어
// Linux·맥과 다른 바이트로 설치되고, 스킬에 든 .sh 는 bash 에서 깨진다(CI 의 세 OS 스냅샷 비교에서 실제로 확인됨). 환경변수 설정은 전역 git 설정보다 우선한다.
{
  const n = parseInt(process.env.GIT_CONFIG_COUNT || '0', 10) || 0;
  process.env.GIT_CONFIG_COUNT = String(n + 1);
  process.env[`GIT_CONFIG_KEY_${n}`] = 'core.autocrlf';
  process.env[`GIT_CONFIG_VALUE_${n}`] = 'false';
}

// ---- 사전 점검: 설치를 시작하기 전에 알려진 함정을 막는다 -----------------------------------------
const win = process.platform === 'win32';
const die = (m) => { console.error(`\n[error] ${m}`); process.exit(2); };
const warn = (m) => console.warn(`[warn] ${m}`);
const probe = (cmd, args, opts = {}) => spawnSync(cmd, args, { shell: win, encoding: 'utf8', timeout: 15000, ...opts });

// 1) Node 22.20+, git, npx. skills CLI(1.5.2x 이후)는 Node 22.20 이상을 요구한다. 그보다 낮은 Node 에서는 `npx -y skills` 가
//    오류 없이 옛 버전(1.5.18)으로 내려가고, 그 버전은 고정 커밋(owner/repo#<커밋>) 설치를 못 해 모든 스킬이 실패한다.
const [nodeMajor, nodeMinor] = process.versions.node.split('.').map(Number);
if (nodeMajor < 22 || (nodeMajor === 22 && nodeMinor < 20)) {
  const msg = `Node.js 22.20 이상이 필요합니다 (현재 ${process.versions.node}). skills CLI 최신판이 이를 요구하고, 더 낮은 Node 에서는 npx 가 조용히 옛 버전(1.5.18)을 받아 고정 커밋 설치가 모두 실패합니다. https://nodejs.org`;
  if (dryRun) warn(msg); else die(msg);
}
if (probe('git', ['--version']).status !== 0) die('git 이 필요합니다 (skills CLI 가 GitHub 저장소를 받습니다). https://git-scm.com');
if (probe('npx', ['--version']).status !== 0) die('npx 가 필요합니다 (Node.js 설치에 포함됩니다).');

// 2) WSL: Windows 의 Claude Code 를 의도했는데 WSL 안에 설치되는 것을 막는다 (bootstrap.sh 의 wsl_guard 와 같은 규칙)
const isWsl = () => platform() === 'linux' && (!!process.env.WSL_DISTRO_NAME || /microsoft/i.test(existsSync('/proc/version') ? readFileSync('/proc/version', 'utf8') : ''));
function windowsClaudeDirs() {
  const base = process.env.AI_SETUP_MNT || '/mnt', found = [];
  try {
    for (const d of readdirSync(base)) {
      try {
        for (const u of readdirSync(join(base, d, 'Users'))) { const c = join(base, d, 'Users', u, '.claude'); if (existsSync(c)) found.push(c); }
      } catch { /* 이 드라이브엔 Users 가 없다 */ }
    }
  } catch { /* /mnt 없음 */ }
  return found;
}
if (isWsl()) {
  const winDirs = windowsClaudeDirs();
  console.log(`    wsl   : WSL 에서 실행 중 — 설치 위치는 WSL 의 ${homedir()} 입니다 (Windows 사용자 폴더 아님)`);
  if (!existsSync(join(homedir(), '.claude')) && winDirs.length && !allowWsl) {
    console.error(`[error] WSL 의 홈(${homedir()})에는 Claude Code 설정(.claude)이 없고, Windows 쪽에는 있습니다:\n      ${winDirs.join('\n      ')}`);
    console.error('    Windows 의 Claude Code 에 설치하려던 것이라면 WSL 이 아니라 Windows(PowerShell)에서 실행하세요:  node scripts\\install-skills.mjs');
    console.error('    WSL 안에 설치하는 것이 맞다면 --wsl 을 붙여 다시 실행하세요.');
    if (!dryRun) process.exit(2);
  }
}

// 3) 오래된 클론: main 을 받은 클론이 origin/main 과 다르면 알린다 (오래된 사본으로 설치하는 것을 막는다)
if (existsSync(join(root, '.git'))) {
  const g = (a) => probe('git', a, { cwd: root, timeout: 8000 });
  const branch = (g(['rev-parse', '--abbrev-ref', 'HEAD']).stdout || '').trim();
  const head = (g(['rev-parse', 'HEAD']).stdout || '').trim();
  if (branch === 'main') {
    const remote = ((g(['ls-remote', 'origin', 'main']).stdout || '').split(/\s/)[0] || '').trim();
    if (remote && head && remote !== head) warn(`이 클론(${head.slice(0, 7)})이 origin/main(${remote.slice(0, 7)})과 다릅니다. 오래된 사본일 수 있습니다. 아래 두 줄을 각각 실행한 뒤 다시 실행하세요 (PowerShell 5.1 은 && 를 지원하지 않아 줄을 나눴습니다):\n      git fetch --depth 1 origin main\n      git reset --hard FETCH_HEAD`);
  }
}
console.log(`==> 설치 대상: ${scope ? '전역(-g)' : '현재 프로젝트'}  홈: ${homedir()}${existsSync(join(homedir(), '.claude')) ? '' : '  (Claude Code 설정 폴더 ~/.claude 가 아직 없습니다. 에이전트는 자동 감지됩니다)'}`);

if (profile === 'minimal') console.log('    minimal: 스킬만 설치합니다. 도구·MCP 서버 등록·curl|sh 는 하지 않고 관리자 권한이 필요 없습니다. 같은 이름의 스킬이 이미 있으면 덮어쓰므로 먼저 --diff 로 확인할 수 있습니다.');

// 설치기가 쓰는 skills CLI 는 manifest/skills-cli.version 의 버전으로 고정한다 (bootstrap.sh 의 SKILLS_CLI 와 같은 파일).
const skillsVer = readFileSync(join(root, 'manifest', 'skills-cli.version'), 'utf8').split(/\r?\n/).map((l) => l.trim()).find((l) => l && !l.startsWith('#')) || '';
if (!/^\d/.test(skillsVer)) { console.error('[error] manifest/skills-cli.version 을 읽지 못했습니다 (예: 1.7.1)'); process.exit(2); }
const SKILLS = `skills@${skillsVer}`;

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


// ---- --diff: 설치하지 않고 기존 스킬과의 겹침을 보여준다 ---------------------------------------------
// skills CLI 는 같은 이름의 스킬이 이미 있으면 확인도 백업도 없이 덮어쓴다(직접 만든 것이라도). 설치 전에 미리 알려 준다.
if (diffMode) {
  const ls = spawnSync('npx', win ? ['-y', SKILLS, 'ls', '--json', ...(scope ? [scope] : [])].map(q) : ['-y', SKILLS, 'ls', '--json', ...(scope ? [scope] : [])],
    { shell: win, encoding: 'utf8', timeout: 120000 });
  let installed;
  try { installed = JSON.parse(ls.stdout.slice(ls.stdout.indexOf('['))); } catch { console.error('[error] 설치된 스킬 목록(skills ls --json)을 읽지 못했습니다.'); process.exit(2); }
  const byName = new Map(installed.map((x) => [x.name, x]));
  const rows = [];   // { name, from, state }
  const classify = (name, repo) => {
    const cur = byName.get(name);
    if (!cur) return 'new';
    if (!cur.source) return 'unknown';
    return cur.source.toLowerCase() === repo.toLowerCase() ? 'same' : 'other';
  };
  const unresolved = [];
  for (const raw of readFileSync(join(root, 'manifest', 'skills.list'), 'utf8').split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) continue;
    const [src, skillsField = '*', tags = ''] = fields(line);
    if (!hasTag(tags, tag)) continue;
    const repo = src.split('#')[0];
    let names;
    if (skillsField === '*') {
      // 와일드카드 소스는 실제 스킬 이름을 알려면 받아서 목록을 봐야 한다.
      const largs = [SKILLS, 'add', src, '--list'];
      if (tags.split(',').map((x) => x.trim()).includes('full-depth')) largs.push('--full-depth');
      console.log(`  … ${repo} 의 스킬 목록 확인 중`);
      const r = spawnSync('npx', win ? ['-y', ...largs].map(q) : ['-y', ...largs], { shell: win, encoding: 'utf8', timeout: 180000 });
      const text = ((r.stdout || '') + '\n' + (r.stderr || '')).replace(/\x1b\[[0-9;?]*[A-Za-z]/g, '');
      const at = text.indexOf('Available Skills');
      const after = at >= 0 ? text.slice(at) : text;
      names = [...after.matchAll(/^\|\s{4}(\S+)\s*$/gm)].map((m) => m[1]);
      if (r.status !== 0 || !names.length) { unresolved.push(repo); continue; }
    } else names = skillsField.split(',').map((x) => x.trim()).filter(Boolean);
    for (const n of names) rows.push({ name: n, from: repo, state: classify(n, repo) });
  }
  if (!tag || tag === 'local') {
    const dir = join(root, 'skills');
    if (existsSync(dir)) for (const d of readdirSync(dir, { withFileTypes: true })) {
      const f = join(dir, d.name, 'SKILL.md');
      if (!d.isDirectory() || !existsSync(f)) continue;
      const m = readFileSync(f, 'utf8').match(/^name:\s*["']?([^"'\r\n]+?)["']?\s*$/m);
      if (m) rows.push({ name: m[1], from: '(이 저장소 skills/)', state: byName.has(m[1]) ? (byName.get(m[1]).source ? 'other' : 'unknown') : 'new' });
    }
  }
  const label = { new: '신규', same: '같은 출처, 다시 설치(갱신)', other: '다른 출처의 같은 이름 → 덮어씀', unknown: '출처 불명의 같은 이름 → 덮어씀(직접 만든 스킬이거나 로컬 설치)' };
  console.log(`\n==> 설치 전 미리보기 (${scope ? '전역' : '현재 프로젝트'}, 이미 설치된 스킬 ${installed.length}개)`);
  for (const st of ['new', 'same', 'other', 'unknown']) {
    const list = rows.filter((r) => r.state === st);
    console.log(`  ${label[st]}: ${list.length}개`);
    if (st === 'other' || st === 'unknown') for (const r of list) console.log(`      ! ${r.name}  (설치될 출처: ${r.from}${st === 'other' ? `, 지금 출처: ${byName.get(r.name).source}` : ''})`);
  }
  if (unresolved.length) console.log(`  이름을 확인하지 못한 와일드카드 소스: ${unresolved.join(', ')} (네트워크 문제일 수 있습니다. 이 소스의 겹침은 알 수 없습니다)`);
  const risky = rows.filter((r) => r.state === 'other' || r.state === 'unknown').length;
  console.log(risky ? `\n[주의] ${risky}개는 같은 이름이 이미 있어 확인 없이 덮어써지고 백업되지 않습니다. 아껴 둔 것이 있으면 먼저 폴더를 복사해 두세요.` : '\n덮어쓰이는 기존 스킬은 없습니다.');
  console.log('아무것도 설치하지 않았습니다.');
  process.exit(0);
}
const failed = [], expectNames = [], expectSources = [];
console.log('==> manifest/skills.list 의 스킬 설치');
for (const raw of readFileSync(join(root, 'manifest', 'skills.list'), 'utf8').split(/\r?\n/)) {
  const line = raw.trim();
  if (!line || line.startsWith('#')) continue;
  const [src, skillsField = '*', tags = ''] = fields(line);
  if (!hasTag(tags, tag)) continue;
  const repo = src.split('#')[0];
  const args = [SKILLS, 'add', src, '-y'];
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
    const args = [SKILLS, 'add', root, '-y'];
    if (scope) args.push(scope);
    args.push(...agentFlags);
    for (const n of localNames) args.push('--skill', n);
    if (npx(args).status !== 0) failed.push('skill:local');
    else {
      expectNames.push(...localNames);
      if (!dryRun && scope === '-g') console.log('  참고: 위 요약의 "✗ … PromptScript: PromptScript does not support global skill installation" 줄은 정상입니다(전역 설치를 지원하지 않는 에이전트를 건너뛴다는 skills CLI 안내). 결과에는 영향이 없습니다.');
    }
  }
}

// 설치 명령이 성공해도 일부가 조용히 빠질 수 있으므로 이름으로 확인한다.
if (!dryRun && (expectNames.length || expectSources.length)) {
  console.log('==> 설치 확인');
  const lsArgs = [SKILLS, 'ls', '--json'];
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
