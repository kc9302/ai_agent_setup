#!/usr/bin/env bash
# 매니페스트 형식을 검사한다. CI 와 커밋 전에 실행.
#   bash scripts/validate.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

errors=0
fail() { error "$*"; errors=$((errors + 1)); }

info "validating $SKILLS_LIST"
declare -A seen=()
n=0
while IFS= read -r -u 3 line; do
  n=$((n + 1))
  split_fields "$line"
  src="${FIELDS[0]:-}"; skills="${FIELDS[1]:-}"; tags="${FIELDS[2]:-}"; desc="${FIELDS[3]:-}"
  [ ${#FIELDS[@]} -eq 4 ] || fail "skills.list: expected 4 fields, got ${#FIELDS[@]}: $line"
  [[ "$src" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(#[0-9a-f]{40})?$ ]] || fail "skills.list: source must be owner/repo#<40자리 커밋>: '$src'"
  [ -n "$(src_ref "$src")" ] || fail "skills.list: $src 가 커밋에 고정되지 않았다 → bash scripts/pin.sh --fill"
  [ -n "$skills" ] || fail "skills.list: skills field empty for $src (use '*')"
  [[ "$skills" =~ ^(\*|[A-Za-z0-9_.-]+([[:space:]]*,[[:space:]]*[A-Za-z0-9_.-]+)*)$ ]] || fail "skills.list: bad skills list for $src: '$skills'"
  [ -n "$desc" ] || fail "skills.list: description empty for $src"
  repo_key="$(src_repo "$src")"; repo_key="${repo_key,,}"
  [ -z "${seen[$repo_key]:-}" ] || fail "skills.list: duplicate source $src"
  seen[$repo_key]=1
done 3< <(manifest_lines "$SKILLS_LIST")
printf '    %d skill source(s)\n' "$n"

info "validating $TOOLS_LIST"
declare -A seen_t=()
n=0
while IFS= read -r -u 3 line; do
  n=$((n + 1))
  split_fields "$line"
  name="${FIELDS[0]:-}"; check="${FIELDS[1]:-}"; install="${FIELDS[2]:-}"; desc="${FIELDS[4]:-}"
  [ ${#FIELDS[@]} -eq 5 ] || fail "tools.list: expected 5 fields, got ${#FIELDS[@]}: $line"
  [ -n "$name" ] || fail "tools.list: name empty"
  [ -n "$check" ] || fail "tools.list: check command empty for $name"
  [ -n "$install" ] || fail "tools.list: install command empty for $name"
  [ -n "$desc" ] || fail "tools.list: description empty for $name"
  bash -n <(printf '%s\n' "$check")   2>/dev/null || fail "tools.list: check is not valid shell for $name"
  bash -n <(printf '%s\n' "$install") 2>/dev/null || fail "tools.list: install is not valid shell for $name"
  [ -z "${seen_t[$name]:-}" ] || fail "tools.list: duplicate tool $name"
  seen_t[$name]=1
done 3< <(manifest_lines "$TOOLS_LIST")
printf '    %d tool(s)\n' "$n"

info "checking local skills/"
for d in "$REPO_ROOT"/skills/*/; do
  [ -d "$d" ] || continue
  if [ ! -f "$d/SKILL.md" ]; then fail "skills/$(basename "$d") has no SKILL.md"; continue; fi
  head -1 "$d/SKILL.md" | grep -q '^---$' || fail "skills/$(basename "$d")/SKILL.md must start with YAML frontmatter"
  grep -q '^name:' "$d/SKILL.md" || fail "skills/$(basename "$d")/SKILL.md missing 'name:'"
  # skills CLI 는 --skill 을 폴더 이름이 아니라 name: 값으로 찾으므로, 둘이 다르면 혼란스럽다.
  lname="$(sed -n 's/^name:[[:space:]]*//p' "$d/SKILL.md" | head -1 | tr -d '\r"'"'"'')"
  [ "$lname" = "$(basename "$d")" ] || fail "skills/$(basename "$d")/SKILL.md: name: '$lname' 이 폴더 이름과 다르다"
  grep -q '^description:' "$d/SKILL.md" || fail "skills/$(basename "$d")/SKILL.md missing 'description:'"
done

info "syntax-checking scripts"
for f in "$REPO_ROOT"/bootstrap.sh "$REPO_ROOT"/scripts/*.sh; do
  bash -n "$f" || fail "syntax error in $f"
done

# bootstrap.sh(bash)와 install-skills.mjs(Node)는 같은 스킬을 같은 명령으로 설치해야 한다. 한쪽만 고치면 환경마다 달라진다.
if command -v node >/dev/null 2>&1; then
  info "checking that install-skills.mjs and bootstrap.sh install the same skills"
  node --check "$REPO_ROOT/scripts/install-skills.mjs" || fail "syntax error in scripts/install-skills.mjs"
  a="$(node "$REPO_ROOT/scripts/install-skills.mjs" --dry-run 2>&1 | grep -o 'npx -y skills add.*' || true)"
  b="$(bash "$REPO_ROOT/bootstrap.sh" --skills-only --dry-run 2>&1 | grep -o 'npx -y skills add.*' || true)"
  if [ -z "$a" ] || [ "$a" != "$b" ]; then
    fail "install-skills.mjs 와 bootstrap.sh 가 설치하는 스킬 명령이 다릅니다 (한쪽만 고쳤는지 확인)"
    diff <(printf '%s\n' "$a") <(printf '%s\n' "$b") | head -6 >&2 || true
  fi
fi

# radar.sh 는 후보 데이터(candidates.json)를 만든다. 제외 규칙과 문자열 정리가 깨지지 않았는지 네트워크 없이 확인한다.
if command -v jq >/dev/null 2>&1; then
  info "testing radar.sh against offline fixtures"
  bash "$REPO_ROOT/scripts/test-radar.sh" >/dev/null || { fail "scripts/test-radar.sh 실패 (bash scripts/test-radar.sh 로 상세 확인)"; }
fi

if [ "$errors" -gt 0 ]; then die "$errors error(s)"; fi
info "all good"
