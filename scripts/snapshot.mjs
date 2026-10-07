#!/usr/bin/env node
// 이 컴퓨터에 설치된 스킬·도구를 JSON 스냅샷으로 남기고, 두 스냅샷을 비교한다. "같은 것이 설치됐다"를 말이 아니라 기록으로 보이기 위한 것이다.
//
//   node scripts/snapshot.mjs > mine.json                 # 스킬 + 도구 스냅샷 (도구 확인은 bash 가 필요하다. Windows 에서는 건너뛴다)
//   node scripts/snapshot.mjs --skills-only > mine.json   # 스킬만 (bash 불필요, 모든 OS)
//   node scripts/snapshot.mjs --diff a.json b.json        # 두 스냅샷 비교. 다르면 종료 코드 1
//
// 스킬은 skills CLI 가 남기는 ~/.agents/.skill-lock.json 에서 읽는다. GitHub 에서 받은 스킬은 고정 커밋(ref)과 폴더 내용 해시(skillFolderHash)가 있어
// "이름이 같다"를 넘어 "내용이 같다"까지 비교할 수 있다. 로컬 경로로 설치한 스킬(이 저장소의 skills/)은 출처 경로가 머신마다 달라 이름만 비교하고,
// 내용 해시 차이는 참고로만 알린다(줄바꿈 설정 차이일 수 있다).
// 스냅샷에는 사용자 이름·경로·시각 같은 개인 정보를 넣지 않는다(host 에는 OS·CPU·Node 버전만).
import { readFileSync, existsSync } from 'node:fs';
import { homedir, platform, arch } from 'node:os';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const argv = process.argv.slice(2);
const win = platform() === 'win32';

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
  let same = 0, localHashDiff = 0;
  for (const n of names) {
    const x = A.skills?.[n], y = B.skills?.[n];
    if (!x) { diffs.push(`스킬 ${n}: 두 번째에만 있음`); continue; }
    if (!y) { diffs.push(`스킬 ${n}: 첫 번째에만 있음`); continue; }
    if (x.type !== y.type) { diffs.push(`스킬 ${n}: 설치 방식이 다릅니다 (${x.type} ≠ ${y.type})`); continue; }
    if (x.type === 'github') {
      if (x.source !== y.source) diffs.push(`스킬 ${n}: 출처가 다릅니다 (${x.source} ≠ ${y.source})`);
      else if (x.ref !== y.ref) diffs.push(`스킬 ${n}: 커밋이 다릅니다 (${(x.ref || '').slice(0, 7)} ≠ ${(y.ref || '').slice(0, 7)})`);
      else if (x.hash !== y.hash) diffs.push(`스킬 ${n}: 같은 커밋인데 폴더 내용 해시가 다릅니다`);
      else same++;
    } else {
      if (x.hash !== y.hash) { localHashDiff++; notes.push(`로컬 스킬 ${n}: 내용 해시가 다릅니다 (줄바꿈 설정 차이일 수 있음)`); }
      same++;
    }
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
  console.log(`  스킬 ${names.length}개 중 이름·출처·커밋·폴더 해시가 모두 같은 것 ${same}개 (로컬 스킬은 이름만 비교)`);
  if (toolsCompared) console.log(`  도구 ${toolsCompared}개를 비교했습니다`);
  else if (tools.length) console.log('  도구는 한쪽 이상에서 확인하지 않아(unchecked) 비교하지 않았습니다');
  for (const n of notes) console.log(`  참고: ${n}`);
  if (diffs.length) { console.log(`\n다른 점 ${diffs.length}건:`); for (const d of diffs) console.log(`  - ${d}`); process.exit(1); }
  console.log('\n차이 없음: 두 환경에 같은 스킬이 같은 내용으로 설치되어 있습니다' + (toolsCompared ? ' (도구도 같은 고정 버전)' : ' (도구는 비교하지 않음)') + '.');
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
    snap.skills[name] = e.sourceType === 'github'
      ? { type: 'github', source: e.source, ref: e.ref, hash: e.skillFolderHash }
      : { type: e.sourceType || 'unknown', hash: e.skillFolderHash };   // 로컬 설치는 출처 경로가 머신마다 다르므로 넣지 않는다
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
