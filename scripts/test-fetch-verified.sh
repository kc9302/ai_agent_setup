#!/usr/bin/env bash
# fetch-verified.sh 를 네트워크 없이(file:// URL) 검증한다.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0; chk() { if [ "$2" = "$3" ]; then echo "  ok  $1"; else echo "  FAIL $1: expected '$3', got '$2'"; fail=1; fi; }
printf 'echo "ran with: $*  MARK=${MARK:-}"\n' > "$T/s.sh"
good="$( (sha256sum "$T/s.sh" 2>/dev/null || shasum -a 256 "$T/s.sh") | awk '{print $1}')"

out="$(MARK=x bash "$ROOT/scripts/fetch-verified.sh" "file://$T/s.sh" "$good" a b 2>&1)"; rc=$?
chk "correct hash runs the script" "$rc" 0
chk "args and env are passed through" "$out" "ran with: a b  MARK=x"

out="$(bash "$ROOT/scripts/fetch-verified.sh" "file://$T/s.sh" "$(printf '0%.0s' $(seq 1 64))" 2>&1)"; rc=$?
chk "wrong hash exits 4" "$rc" 4
chk "wrong hash does not run the script" "$(printf '%s' "$out" | grep -c 'ran with')" 0

bash "$ROOT/scripts/fetch-verified.sh" "file://$T/missing.sh" "$good" >/dev/null 2>&1; chk "download failure exits 3" "$?" 3
bash "$ROOT/scripts/fetch-verified.sh" "file://$T/s.sh" "abc" >/dev/null 2>&1; chk "malformed hash exits 2" "$?" 2
bash "$ROOT/scripts/fetch-verified.sh" >/dev/null 2>&1; chk "no args exits 2" "$?" 2
printf 'exit 7\n' > "$T/e.sh"; eg="$( (sha256sum "$T/e.sh" 2>/dev/null || shasum -a 256 "$T/e.sh") | awk '{print $1}')"
bash "$ROOT/scripts/fetch-verified.sh" "file://$T/e.sh" "$eg" >/dev/null 2>&1; chk "script exit code is returned" "$?" 7
# 임시 파일은 성공·해시 불일치·다운로드 실패 어느 경우에도 남지 않아야 한다 (TMPDIR 을 전용 폴더로 돌려 센다)
mkdir "$T/tmpd"
TMPDIR="$T/tmpd" bash "$ROOT/scripts/fetch-verified.sh" "file://$T/s.sh" "$good" >/dev/null 2>&1
TMPDIR="$T/tmpd" bash "$ROOT/scripts/fetch-verified.sh" "file://$T/s.sh" "$(printf '0%.0s' $(seq 1 64))" >/dev/null 2>&1
TMPDIR="$T/tmpd" bash "$ROOT/scripts/fetch-verified.sh" "file://$T/nope.sh" "$good" >/dev/null 2>&1
chk "temp files are cleaned up (ok / mismatch / download failure)" "$(ls -A "$T/tmpd" | wc -l | tr -d ' ')" 0
exit $fail
