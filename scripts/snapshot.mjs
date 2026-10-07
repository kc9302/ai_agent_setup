#!/usr/bin/env node
// 이 컴퓨터에 설치된 스킬·도구를 JSON 스냅샷으로 남기고, 두 스냅샷을 비교한다. "같은 것이 설치됐다"를 말이 아니라 기록으로 보이기 위한 것이다.
//
//   node scripts/snapshot.mjs > mine.json                 # 스킬 + 도구 스냅샷 (도구 확인은 bash 가 필요하다. Windows 에서는 건너뛴다)
//   node scripts/snapshot.mjs --skills-only > mine.json   # 스킬만 (bash 불필요, 모든 OS)
//   node scripts/snapshot.mjs --diff a.json b.json        # 두 스냅샷 비교. 다르면 종료 코드 1
//
// 스킬의 출처와 고정 커밋은 skills CLI 가 남기는 ~/.agents/.skill-lock.json 에서 읽는다. 내용은 **설치된 폴더의 파일을 이 스크립트가 직접 해시**해서 비교한다.
// (잠금 파일의 skillFolderHash 는 비교에 쓰지 않는다: skills CLI 가 GitHub API 로 트리를 받으면 40자리 git 트리 해시를, API 가 실패하면 파일을 직접 해시한
//  64자리 값을 기록하므로, 같은 스킬이라도 환경마다 값의 종류가 달라진다. CI 에서 실제로 그런 일이 있었다.)
// 줄바꿈만 다른 경우(Windows 의 git autocrlf)는 따로 구분해서 알린다. 로컬 경로로 설치한 스킬(이 저장소의 skills/)은 출처 경로가 머신마다 달라 이름과 내용만 본다.
// 스냅샷에는 사용자 이름·경로·시각 같은 개인 정보를 넣지 않는다(host 에는 OS·CPU·Node 버전만).
import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { homedir, platform, arch } from 'node:os';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const argv = process.argv.slice(2);
const win = platform() === 'win32';


// 설치된 스킬 폴더의 내용 해시: 상대 경로(/ 구분, 바이트 순서로 정렬) + 파일 내용. .git, node_modules 는 뺀다.
// lf 는 텍스트 파일의 CRLF 를 LF 로 바꾼 값(줄바꿈 차이만 따로 가려내기 위함). NUL 바이트가 있으면 바이너리로 보고 그대로 둔다.
function folderHashes(dir) {
  const files = [];
  const walk = (cur) => {
    for (const e of readdirSync(cur, { withFileTypes: true })) {
      const full = join(cur, e.name);
      if (e.isDirectory()) { if (e.name !== '.git' && e.name !== 'node_modules') walk(full); }
      else if (e.isFile()) files.push([full.slice(dir.length + 1).split('\\').join('/'), readFileSync(full)]);
    }
  };
  walk(dir);
  files.sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0));
  const raw = createHash('sha256'), lf = createHash('sha256');
  for (const [rel, buf] of files) {
    raw.update(rel); raw.update('\0'); raw.update(buf);
    const isText = !buf.subarray(0, 8000).includes(0);
    lf.update(rel); lf.update('\0'); lf.update(isText ? Buffer.from(buf.toString('latin1').replaceAll('\r\n', '\n'), 'latin1') : buf);
  }
  return { content: raw.digest('hex'), content_lf: lf.digest('hex'), files: files.length };
}

// ---- 비교 -----------------------------------------------------------------------------------------------
if (argv[0] === '--diff') {
  const [a, b] = [argv[1], argv[2]];
  if (!a || !b) { console.error('usage: snapshot.mjs --diff <a.json> <b.json>'); process.exit(2); }
  const A = JSON.parse(readFileSync(a, 'utf8')), B = JSON.parse(readFileSync(b, 'utf8'));
  const diffs = [], notes = [];
  const label = (s) => `${s.host?.platform ?? '?'}/${s.host?.arch ?? '?'}`;

  if (A.repo?.commit && B.repo?.commit && A.repo.commit !== B.repo.commit) diffs.push(`저장소 커밋이 다릅니다: ${A.repo.commit.slice(0, 7)} ≠ ${B.repo.commit.slice(0, 7)} (매니페스트가 달랐을 수 있습니다)`);
  if (A.skills_cli?.expected !== B.skills_cli?.expected) diffs.push(`설치기가 쓰는 skills CLI 버전이 다릅니다: ${A.skills_cli?.expected} ≠ ${B.skills_cli?.expected}`);

  const names = [...new Set([...Object.keys(A.skills || {}), ...Object.keys(B.skills || {})])].sort();
  let same = 0, eolOnly = 0, unreadable = 0;
  // 내용 비교: 둘 다 읽었을 때만. 같음 / 줄바꿈만 다름 / 내용이 다름 / 비교 불가
  const compareContent = (n, x, y, strict) => {
    if (!x.content || !y.content) { unreadable++; notes.push(`스킬 ${n}: 설치된 폴더를 읽지 못해 내용은 비교하지 못했습니다`); return 'skip'; }
    if (x.content === y.content) return 'same';
    if (x.content_lf === y.content_lf) { eolOnly++; (strict ? diffs : notes).push(`스킬 ${n}: 줄바꿈(CRLF/LF)만 다릅니다 (Windows 의 git autocrlf 설정일 수 있음)`); return 'eol'; }
    (strict ? diffs : notes).push(`스킬 ${n}: ${strict ? '같은 커밋인데 ' : ''}설치된 파일 내용이 다릅니다`); return 'differs';
  };
  for (const n of names) {
    const x = A.skills?.[n], y = B.skills?.[n];
    if (!x) { diffs.push(`스킬 ${n}: 두 번째에만 있음`); continue; }
    if (!y) { diffs.push(`스킬 ${n}: 첫 번째에만 있음`); continue; }
    if (x.type !== y.type) { diffs.push(`스킬 ${n}: 설치 방식이 다릅니다 (${x.type} ≠ ${y.type})`); continue; }
    if (x.type === 'github') {
      if (x.source !== y.source) diffs.push(`스킬 ${n}: 출처가 다릅니다 (${x.source} ≠ ${y.source})`);
      else if (x.ref !== y.ref) diffs.push(`스킬 ${n}: 커밋이 다릅니다 (${(x.ref || '').slice(0, 7)} ≠ ${(y.ref || '').slice(0, 7)})`);
      else if (compareContent(n, x, y, true) === 'same') same++;
    } else if (compareContent(n, x, y, false) === 'same') same++;   // 로컬 스킬은 이름·내용만 보고, 내용 차이는 참고로만 알린다
  }

  const tools = [...new Set([...Object.keys(A.tools || {}), ...Object.keys(B.tools || {})])].sort();
  let toolsCompared = 0;
  for (const t of tools) {
    const x = A.tools?.[t], y = B.tools?.[t];
    if (!x || !y) { diffs.push(`도구 ${t}: 한쪽 스냅샷에만 있음`); continue; }
    if (x.check === 'unchecked' || y.check === 'unchecked') continue;
    toolsCompared++;
    if (x.pinned !== y.pinned) diffs.push(`도구 ${t}: 고정 버전이 다릅니다 (${x.pinned} ≠ ${y.pinned})`);
    else if (x.check !== y.check) diffs.push(`도구 ${t}: 고정 버전 확인 결과가 다릅니다 (${x.check} ≠ ${y.check})`);
  }
  for (const k of ['npm_globals', 'uv_tools']) {
    const keys = [...new Set([...Object.keys(A[k] || {}), ...Object.keys(B[k] || {})])].sort();
    if (A[k] === undefined || B[k] === undefined) continue;
    for (const p of keys) if ((A[k][p] ?? '(없음)') !== (B[k][p] ?? '(없음)')) diffs.push(`${k === 'npm_globals' ? 'npm 전역' : 'uv 도구'} ${p}: ${A[k][p] ?? '(없음)'} ≠ ${B[k][p] ?? '(없음)'}`);
  }

  console.log(`비교: ${label(A)} (Node ${A.host?.node}) ↔ ${label(B)} (Node ${B.host?.node})`);
  console.log(`  스킬 ${names.length}개 중 이름·출처·커밋·설치된 파일 내용이 모두 같은 것 ${same}개 (로컬 스킬은 출처를 보지 않음)`);
  if (eolOnly) console.log(`  그중 줄바꿈만 다른 것 ${eolOnly}개`);
  if (unreadable) console.log(`  설치된 폴더를 읽지 못해 내용을 비교하지 못한 것 ${unreadable}개`);
  if (toolsCompared) console.log(`  도구 ${toolsCompared}개를 비교했습니다`);
  else if (tools.length) console.log('  도구는 한쪽 이상에서 확인하지 않아(unchecked) 비교하지 않았습니다');
  for (const n of notes) console.log(`  참고: ${n}`);
  if (diffs.length) { console.log(`\n다른 점 ${diffs.length}건:`); for (const d of diffs) console.log(`  - ${d}`); process.exit(1); }
  console.log('\n차이 없음: 두 환경에 같은 스킬이 같은 커밋·같은 파일 내용으로 설치되어 있습니다' + (toolsCompared ? ' (도구도 같은 고정 버전)' : ' (도구는 비교하지 않음)') + '.');
  process.exit(0);
}

// ---- 스냅샷 만들기 ---------------------------------------------------------------------------------------
const skillsOnly = argv.includes('--skills-only');
const run = (cmd, args, opts = {}) => spawnSync(cmd, args, { shell: win, encoding: 'utf8', timeout: 60000, ...opts });
const lines = (file) => readFileSync(file, 'utf8').split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
const fields = (line) => line.replaceAll('\\|', '\x01').replaceAll('||', '\x02').split('|').map((f) => f.replaceAll('\x01', '|').replaceAll('\x02', '||').trim());

const snap = { schema: 1, host: { platform: platform(), arch: arch(), node: process.versions.node } };
if (existsSync(join(root, '.git'))) snap.repo = { commit: (run('git', ['rev-parse', 'HEAD'], { cwd: root }).stdout || '').trim() };
snap.skills_cli = { expected: lines(join(root, 'manifest', 'skills-cli.version'))[0] };

// 스킬: skills CLI 의 전역 잠금 파일
const lockPath = join(homedir(), '.agents', '.skill-lock.json');
snap.skills = {};
if (existsSync(lockPath)) {
  const lock = JSON.parse(readFileSync(lockPath, 'utf8'));
  for (const name of Object.keys(lock.skills || {}).sort()) {
    const e = lock.skills[name];
    const base = e.sourceType === 'github' ? { type: 'github', source: e.source, ref: e.ref } : { type: e.sourceType || 'unknown' };   // 로컬 설치는 출처 경로를 넣지 않는다
    const dir = join(homedir(), '.agents', 'skills', name);
    const h = existsSync(dir) ? folderHashes(dir) : null;
    snap.skills[name] = { ...base, content: h?.content ?? null, content_lf: h?.content_lf ?? null };
  }
} else console.error(`[warn] ${lockPath} 이 없습니다: 전역으로 설치된 스킬이 없거나 skills CLI 가 다른 위치에 기록했습니다.`);

// 도구: tools.list 의 check 를 실행해 "고정한 버전이다"를 확인한다 (bash 필요)
if (!skillsOnly) {
  const pinnedVersion = (ins) => {
    let m = ins.match(/(?:^|[^=])==([0-9][0-9A-Za-z.+-]*)/); if (m) return m[1];
    m = ins.match(/(?:npm install -g|npx -y) +(?:@[^/@ ]+\/)?[^@/ ]+@([0-9][0-9A-Za-z.+-]*)/); if (m) return m[1];
    m = ins.match(/\/v?([0-9]+\.[0-9]+\.[0-9]+)\//); if (m) return m[1];
    m = ins.match(/(?:@|checkout -q )([0-9a-f]{40})/); if (m) return `commit ${m[1].slice(0, 7)}`;
    return null;
  };
  const canBash = !win || !!process.env.AI_SETUP_BASH;   // Windows 의 `bash` 는 WSL 일 수 있어 명시했을 때만 쓴다
  const bash = process.env.AI_SETUP_BASH || 'bash';
  snap.tools = {};
  const npmNames = new Set(), uvNames = new Set();
  for (const line of lines(join(root, 'manifest', 'tools.list'))) {
    const [name, check, install] = fields(line);
    for (const m of install.matchAll(/(?:npm install -g|npx -y) +((?:@[^/@ ]+\/)?[^@/ ]+)@[0-9]/g)) npmNames.add(m[1]);
    for (const m of install.matchAll(/['"]?([A-Za-z0-9_.-]+)(?:\[[^\]]*\])?==[0-9]/g)) uvNames.add(m[1]);
    let status = 'unchecked';
    if (canBash) status = run(bash, ['-c', check], { env: { ...process.env, AI_SETUP_ROOT: root }, stdio: 'ignore' }).status === 0 ? 'ok' : 'fail';
    snap.tools[name] = { pinned: pinnedVersion(install), check: status };
  }
  const npmLs = run('npm', ['ls', '-g', '--depth=0', '--json']);
  try {
    const deps = JSON.parse(npmLs.stdout || '{}').dependencies || {};
    snap.npm_globals = Object.fromEntries([...npmNames].sort().map((n) => [n, deps[n]?.version]).filter(([, v]) => v));
  } catch { /* npm 이 없거나 출력이 비었다 */ }
  const uvLs = run('uv', ['tool', 'list']);
  if (uvLs.status === 0) {
    snap.uv_tools = {};
    for (const l of (uvLs.stdout || '').split(/\r?\n/)) { const m = l.match(/^([A-Za-z0-9_.-]+) v(\S+)/); if (m && (uvNames.has(m[1]) || m[1] === 'agent-reach')) snap.uv_tools[m[1]] = m[2]; }
  }
}
console.log(JSON.stringify(snap, null, 2));
