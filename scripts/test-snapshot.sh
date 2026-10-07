#!/usr/bin/env bash
# snapshot.mjs 의 스냅샷 생성과 --diff 를 가짜 잠금 파일·스냅샷으로 검증한다(네트워크 불필요).
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v node >/dev/null 2>&1 || { echo "node 가 없어 건너뜁니다"; exit 0; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0; chk() { if [ "$2" = "$3" ]; then echo "  ok  $1"; else echo "  FAIL $1: expected '$3', got '$2'"; fail=1; fi; }
H1="$T/h1"; mkdir -p "$H1/.agents"
cat > "$H1/.agents/.skill-lock.json" <<'JSON'
{"version":3,"skills":{
 "alpha":{"source":"o/r","sourceType":"github","sourceUrl":"https://github.com/o/r.git","ref":"1111111111111111111111111111111111111111","skillFolderHash":"aaa"},
 "beta": {"source":"o/r","sourceType":"github","sourceUrl":"https://github.com/o/r.git","ref":"1111111111111111111111111111111111111111","skillFolderHash":"bbb"},
 "mine": {"source":"/home/secret-user/work/repo","sourceType":"local","sourceUrl":"/home/secret-user/work/repo","skillFolderHash":"lll"}}}
JSON
HOME="$H1" USERPROFILE="$H1" node "$ROOT/scripts/snapshot.mjs" --skills-only > "$T/a.json" 2>"$T/err"; chk "snapshot is created" "$?" 0
chk "github skill keeps source, commit and hash" "$(node -e 'const s=require(process.argv[1]).skills.alpha;console.log(s.type,s.source,s.ref.slice(0,3),s.hash)' "$T/a.json")" "github o/r 111 aaa"
chk "local skill has no source path" "$(grep -c 'secret-user' "$T/a.json")" 0
chk "host holds only os/arch/node" "$(node -e 'console.log(Object.keys(require(process.argv[1]).host).sort().join())' "$T/a.json")" "arch,node,platform"

mut() { node -e 'const fs=require("fs");const s=JSON.parse(fs.readFileSync(process.argv[1]));eval(process.argv[2]);fs.writeFileSync(process.argv[3],JSON.stringify(s))' "$T/a.json" "$1" "$T/b.json"; }
d() { node "$ROOT/scripts/snapshot.mjs" --diff "$T/a.json" "$T/b.json" 2>&1; }

mut ''; out="$(d)"; rc=$?; chk "identical -> exit 0" "$rc" 0; chk "identical -> says no difference" "$(printf '%s' "$out" | grep -c '차이 없음')" 1
mut 's.host.platform="win32";s.host.node="99.0.0"'; d >/dev/null; chk "different host is ignored" "$?" 0
mut 's.skills.alpha.ref="2222222222222222222222222222222222222222"'; out="$(d)"; chk "different commit -> exit 1" "$?" 1; chk "names the skill and the commit" "$(printf '%s' "$out" | grep -c 'alpha.*커밋이 다릅니다')" 1
mut 's.skills.beta.hash="zzz"'; out="$(d)"; chk "same commit, different folder hash -> exit 1" "$?" 1
mut 'delete s.skills.beta'; out="$(d)"; chk "missing skill -> exit 1" "$?" 1; chk "says which side lacks it" "$(printf '%s' "$out" | grep -c 'beta: 첫 번째에만')" 1
mut 's.skills.extra={type:"github",source:"o/x",ref:"3",hash:"x"}'; d >/dev/null; chk "extra skill -> exit 1" "$?" 1
mut 's.skills.alpha.source="o/other"'; d >/dev/null; chk "different source -> exit 1" "$?" 1
mut 's.skills.mine.hash="different"'; out="$(d)"; chk "local hash difference is a note, exit 0" "$?" 0; chk "local hash note is printed" "$(printf '%s' "$out" | grep -c '로컬 스킬 mine')" 1
mut 's.skills_cli.expected="9.9.9"'; d >/dev/null; chk "different skills CLI version -> exit 1" "$?" 1
# 도구
node -e 'const fs=require("fs");const s=JSON.parse(fs.readFileSync(process.argv[1]));s.tools={kordoc:{pinned:"4.19.2",check:"ok"},uv:{pinned:"0.12.23",check:"ok"}};fs.writeFileSync(process.argv[1],JSON.stringify(s))' "$T/a.json"
mut ''; d >/dev/null; chk "tools: same -> exit 0" "$?" 0
mut 's.tools.kordoc.check="fail"'; out="$(d)"; chk "tools: pinned version not met on one side -> exit 1" "$?" 1; chk "tools: names the tool" "$(printf '%s' "$out" | grep -c '도구 kordoc')" 1
mut 's.tools.kordoc.check="unchecked"'; d >/dev/null; chk "tools: unchecked side is skipped, exit 0" "$?" 0
mut 's.npm_globals={kordoc:"4.18.8"}'; node -e 'const fs=require("fs");const s=JSON.parse(fs.readFileSync(process.argv[1]));s.npm_globals={kordoc:"4.19.2"};fs.writeFileSync(process.argv[1],JSON.stringify(s))' "$T/a.json"; d >/dev/null; chk "tools: installed npm version differs -> exit 1" "$?" 1
exit $fail
