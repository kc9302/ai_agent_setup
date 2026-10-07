#!/usr/bin/env bash
# snapshot.mjs 의 스냅샷 생성과 --diff 를 가짜 홈 폴더(잠금 파일 + 스킬 폴더)로 검증한다(네트워크 불필요).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "node 가 없어 건너뜁니다"; exit 0; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0; chk() { if [ "$2" = "$3" ]; then echo "  ok  $1"; else echo "  FAIL $1: expected '$3', got '$2'"; fail=1; fi; }
C1=1111111111111111111111111111111111111111

# mkhome <dir> <cli-hash 종류: git|content> : alpha, beta(GitHub), mine(로컬) 스킬이 설치된 가짜 홈
mkhome() {
  local H="$1" kind="$2" a b
  mkdir -p "$H/.agents/skills/alpha/ref" "$H/.agents/skills/beta" "$H/.agents/skills/mine"
  printf 'alpha skill\nline two\n' > "$H/.agents/skills/alpha/SKILL.md"; printf 'ref\n' > "$H/.agents/skills/alpha/ref/a.md"
  printf 'beta skill\n' > "$H/.agents/skills/beta/SKILL.md"; printf 'mine skill\n' > "$H/.agents/skills/mine/SKILL.md"
  if [ "$kind" = git ]; then a=$(printf 'a%.0s' $(seq 1 40)); b=$(printf 'b%.0s' $(seq 1 40)); else a=$(printf 'c%.0s' $(seq 1 64)); b=$(printf 'd%.0s' $(seq 1 64)); fi
  cat > "$H/.agents/.skill-lock.json" <<JSON
{"version":3,"skills":{
 "alpha":{"source":"o/r","sourceType":"github","sourceUrl":"https://github.com/o/r.git","ref":"$C1","skillFolderHash":"$a"},
 "beta": {"source":"o/r","sourceType":"github","sourceUrl":"https://github.com/o/r.git","ref":"$C1","skillFolderHash":"$b"},
 "mine": {"source":"/home/secret-user/work/repo","sourceType":"local","sourceUrl":"/home/secret-user/work/repo","skillFolderHash":"lll"}}}
JSON
}
snap() { HOME="$1" USERPROFILE="$1" node "$ROOT/scripts/snapshot.mjs" --skills-only 2>/dev/null; }
d() { node "$ROOT/scripts/snapshot.mjs" --diff "$1" "$2" 2>&1; }

mkhome "$T/h1" git; snap "$T/h1" > "$T/a.json"; chk "snapshot is created" "$?" 0
chk "github skill keeps source and commit" "$(node -e 'const s=require(process.argv[1]).skills.alpha;console.log(s.type,s.source,s.ref.slice(0,3))' "$T/a.json")" "github o/r 111"
chk "content hashes come from the installed files" "$(node -e 'const s=require(process.argv[1]).skills.alpha;console.log(/^[0-9a-f]{64}$/.test(s.content)&&/^[0-9a-f]{64}$/.test(s.content_lf))' "$T/a.json")" true
chk "the CLI's own folder hash is not stored" "$(grep -c 'skillFolderHash\|"hash"' "$T/a.json")" 0
chk "local skill has no source path" "$(grep -c 'secret-user' "$T/a.json")" 0
chk "host holds only os/arch/node" "$(node -e 'console.log(Object.keys(require(process.argv[1]).host).sort().join())' "$T/a.json")" "arch,node,platform"

# 회귀: 같은 파일인데 skills CLI 가 기록한 해시의 종류만 다름(GitHub API 성공=40자리 git 트리 / 실패=64자리 내용). CI 에서 실제로 있었던 일.
mkhome "$T/h2" content; snap "$T/h2" > "$T/b.json"
out="$(d "$T/a.json" "$T/b.json")"; chk "same files, different CLI hash kind -> exit 0" "$?" 0; chk "says the contents are identical" "$(printf '%s' "$out" | grep -c '차이 없음')" 1

# 파일 내용이 실제로 다름
mkhome "$T/h3" git; printf 'alpha skill CHANGED\nline two\n' > "$T/h3/.agents/skills/alpha/SKILL.md"; snap "$T/h3" > "$T/b.json"
out="$(d "$T/a.json" "$T/b.json")"; chk "different file content -> exit 1" "$?" 1; chk "names the skill" "$(printf '%s' "$out" | grep -c 'alpha.*파일 내용이 다릅니다')" 1
# 하위 폴더 파일 하나만 다름
mkhome "$T/h4" git; printf 'ref CHANGED\n' > "$T/h4/.agents/skills/alpha/ref/a.md"; snap "$T/h4" > "$T/b.json"; d "$T/a.json" "$T/b.json" >/dev/null; chk "a nested file changing is detected" "$?" 1
# 줄바꿈만 다름 (github 는 다름으로 취급하되 원인을 구분해서 알린다)
mkhome "$T/h5" git; printf 'alpha skill\r\nline two\r\n' > "$T/h5/.agents/skills/alpha/SKILL.md"; snap "$T/h5" > "$T/b.json"
out="$(d "$T/a.json" "$T/b.json")"; chk "CRLF-only difference -> exit 1" "$?" 1; chk "says it is line endings only" "$(printf '%s' "$out" | grep -c 'alpha: 줄바꿈')" 1
# 로컬 스킬의 내용 차이: 같은 저장소 커밋에서 설치했다면 실패, 저장소 커밋이 다르거나 모르면 참고로만
mkhome "$T/h6" git; printf 'mine skill CHANGED\n' > "$T/h6/.agents/skills/mine/SKILL.md"; snap "$T/h6" > "$T/b.json"
out="$(d "$T/a.json" "$T/b.json")"; chk "local skill content differs at the same repo commit -> exit 1" "$?" 1; chk "names the local skill" "$(printf '%s' "$out" | grep -c '스킬 mine: 같은 커밋인데')" 1
node -e 'const fs=require("fs");const a=JSON.parse(fs.readFileSync(process.argv[1]));a.repo={commit:"1".repeat(40)};fs.writeFileSync(process.argv[1],JSON.stringify(a));const b=JSON.parse(fs.readFileSync(process.argv[2]));b.repo={commit:"2".repeat(40)};fs.writeFileSync(process.argv[2],JSON.stringify(b))' "$T/a.json" "$T/b.json"
out="$(d "$T/a.json" "$T/b.json")"; chk "local skill differs but repo commits differ -> only repo commit is reported" "$(printf '%s' "$out" | grep -c '참고: 스킬 mine')" 1
snap "$T/h1" > "$T/a.json"
# 설치된 폴더를 못 읽는 경우
mkhome "$T/h7" git; rm -rf "$T/h7/.agents/skills/beta"; snap "$T/h7" > "$T/b.json"; out="$(d "$T/a.json" "$T/b.json")"; chk "unreadable folder is reported, not guessed" "$(printf '%s' "$out" | grep -c '참고: 스킬 beta.*읽지 못해')" 1

mut() { node -e 'const fs=require("fs");const s=JSON.parse(fs.readFileSync(process.argv[1]));eval(process.argv[2]);fs.writeFileSync(process.argv[3],JSON.stringify(s))' "$T/a.json" "$1" "$T/b.json"; }
mut ''; d "$T/a.json" "$T/b.json" >/dev/null; chk "identical -> exit 0" "$?" 0
mut 's.host.platform="win32";s.host.node="99.0.0"'; d "$T/a.json" "$T/b.json" >/dev/null; chk "different host is ignored" "$?" 0
mut 's.skills.alpha.ref="2222222222222222222222222222222222222222"'; out="$(d "$T/a.json" "$T/b.json")"; chk "different commit -> exit 1" "$?" 1; chk "names the skill and the commit" "$(printf '%s' "$out" | grep -c 'alpha.*커밋이 다릅니다')" 1
mut 'delete s.skills.beta'; out="$(d "$T/a.json" "$T/b.json")"; chk "missing skill -> exit 1" "$?" 1; chk "says which side lacks it" "$(printf '%s' "$out" | grep -c 'beta: 첫 번째에만')" 1
mut 's.skills.extra={type:"github",source:"o/x",ref:"3",content:"x",content_lf:"x"}'; d "$T/a.json" "$T/b.json" >/dev/null; chk "extra skill -> exit 1" "$?" 1
mut 's.skills.alpha.source="o/other"'; d "$T/a.json" "$T/b.json" >/dev/null; chk "different source -> exit 1" "$?" 1
mut 's.skills_cli.expected="9.9.9"'; d "$T/a.json" "$T/b.json" >/dev/null; chk "different skills CLI version -> exit 1" "$?" 1
# 도구
node -e 'const fs=require("fs");const s=JSON.parse(fs.readFileSync(process.argv[1]));s.tools={kordoc:{pinned:"4.19.2",check:"ok"},uv:{pinned:"0.12.23",check:"ok"}};s.npm_globals={kordoc:"4.19.2"};fs.writeFileSync(process.argv[1],JSON.stringify(s))' "$T/a.json"
mut ''; d "$T/a.json" "$T/b.json" >/dev/null; chk "tools: same -> exit 0" "$?" 0
mut 's.tools.kordoc.check="fail"'; out="$(d "$T/a.json" "$T/b.json")"; chk "tools: pinned version not met on one side -> exit 1" "$?" 1; chk "tools: names the tool" "$(printf '%s' "$out" | grep -c '도구 kordoc')" 1
mut 's.tools.kordoc.check="unchecked"'; d "$T/a.json" "$T/b.json" >/dev/null; chk "tools: unchecked side is skipped, exit 0" "$?" 0
mut 's.npm_globals={kordoc:"4.18.8"}'; d "$T/a.json" "$T/b.json" >/dev/null; chk "tools: installed npm version differs -> exit 1" "$?" 1

# 빈 스냅샷은 "같다"가 아니다 (둘 다 비어 있어도 exit 0 이 되던 구멍)
echo '{"schema":1,"host":{"platform":"x","arch":"y","node":"1"},"skills_cli":{"expected":"1"},"skills":{}}' > "$T/e1.json"; cp "$T/e1.json" "$T/e2.json"
out="$(d "$T/e1.json" "$T/e2.json")"; chk "two empty snapshots -> exit 1" "$?" 1; chk "says the snapshot has no skills" "$(printf '%s' "$out" | grep -c '스킬이 하나도 없습니다')" 2

# --check: manifest 대조 (가짜 저장소 루트: 작은 manifest + 로컬 스킬 1개)
R="$T/root"; mkdir -p "$R/scripts" "$R/manifest" "$R/skills/mine"; cp "$ROOT/scripts/snapshot.mjs" "$R/scripts/"
printf 'x\n' > "$R/manifest/skills-cli.version"; printf -- '---\nname: mine\n---\n' > "$R/skills/mine/SKILL.md"
cat > "$R/manifest/skills.list" <<LIST
o/r#$C1 | alpha,beta | core,x | named
w/all#$C1 | * | y | wildcard, not core
LIST
chkj() { node "$R/scripts/snapshot.mjs" --check "$T/c.json" "$@" 2>&1; }
mkc() { node -e 'const fs=require("fs");const C=process.argv[1];const s={schema:1,skills:{alpha:{type:"github",source:"o/r",ref:C},beta:{type:"github",source:"O/R",ref:C},wild1:{type:"github",source:"w/all",ref:C},mine:{type:"local"}}};eval(process.argv[2]);fs.writeFileSync(process.argv[3],JSON.stringify(s))' "$C1" "$1" "$T/c.json"; }
mkc ''; out="$(chkj)"; chk "check: complete install -> exit 0" "$?" 0; chk "check: reports a match" "$(printf '%s' "$out" | grep -c '일치')" 1
mkc 'delete s.skills.beta'; out="$(chkj)"; chk "check: missing named skill -> exit 1" "$?" 1; chk "check: names it" "$(printf '%s' "$out" | grep -c '스킬 beta.*설치되어 있지 않습니다')" 1
mkc 's.skills.alpha.ref="2".repeat(40)'; out="$(chkj)"; chk "check: wrong commit -> exit 1" "$?" 1; chk "check: names the skill" "$(printf '%s' "$out" | grep -c 'alpha.*커밋이')" 1
mkc 'delete s.skills.wild1'; out="$(chkj)"; chk "check: wildcard source with no skill -> exit 1" "$?" 1; chk "check: names the source" "$(printf '%s' "$out" | grep -c 'w/all')" 1
mkc 'delete s.skills.mine'; chkj >/dev/null; chk "check: missing local skill (full) -> exit 1" "$?" 1
mkc 'delete s.skills.mine;delete s.skills.wild1'; chkj --profile minimal >/dev/null; chk "check: minimal ignores non-core sources and local skills -> exit 0" "$?" 0
mkc 's.skills={}'; out="$(chkj)"; chk "check: empty snapshot -> exit 1" "$?" 1; chk "check: says the snapshot is empty" "$(printf '%s' "$out" | grep -c '스냅샷에 스킬이 하나도')" 1
exit $fail
