#!/usr/bin/env bash
# 공용 함수. 각 스크립트에서 `source "$(dirname "$0")/lib.sh"` 로 불러온다.
# 의존성: bash 4+, coreutils. (jq/yq 불필요)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_DIR="$REPO_ROOT/manifest"
SKILLS_LIST="$MANIFEST_DIR/skills.list"
TOOLS_LIST="$MANIFEST_DIR/tools.list"

# ---- 출력 -------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_RESET=$'\033[0m'
else
  C_BOLD=''; C_DIM=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi
info()  { printf '%s==>%s %s\n' "$C_GREEN"  "$C_RESET" "$*"; }
warn()  { printf '%s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
error() { printf '%s[error]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()   { error "$@"; exit 1; }

# ---- 문자열 -----------------------------------------------------------------
trim() {
  local s="$*"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# ---- 매니페스트 파싱 ---------------------------------------------------------
# 주석/빈 줄을 제거한 뒤 각 줄을 stdout 으로 내보낸다.
manifest_lines() {
  local file="$1"
  [ -f "$file" ] || die "manifest not found: $file"
  grep -Ev '^[[:space:]]*(#|$)' "$file"
}

# 한 줄을 '|' 기준으로 나눠 전역 배열 FIELDS 에 넣는다 (각 필드 trim).
# 구분자는 '|' 하나. 필드 안에서 셸 파이프를 쓰려면 '\|' 로 이스케이프한다.
# '||' (셸 OR) 는 구분자로 취급하지 않으므로 그대로 써도 된다.
split_fields() {
  local line="$1" raw
  FIELDS=()
  line="${line//\\|/$'\x01'}"
  line="${line//||/$'\x02'}"
  IFS='|' read -r -a raw <<<"$line"
  local f
  for f in "${raw[@]}"; do f="${f//$'\x01'/|}"; f="${f//$'\x02'/||}"; FIELDS+=("$(trim "$f")"); done
}

# 쉼표 구분 태그 문자열에 특정 태그가 있는지
has_tag() {
  local tags="$1" want="$2" t
  [ -z "$want" ] && return 0
  IFS=',' read -r -a _tags <<<"$tags"
  for t in "${_tags[@]}"; do
    [ "$(trim "$t")" = "$want" ] && return 0
  done
  return 1
}

# ---- GitHub API -------------------------------------------------------------
gh_api() {
  local path="$1"
  local -a hdr=(-H 'Accept: application/vnd.github+json' -H 'User-Agent: ai_agent_setup')
  if [ -n "${GITHUB_TOKEN:-}" ]; then hdr+=(-H "Authorization: Bearer $GITHUB_TOKEN"); fi
  curl -fsSL "${hdr[@]}" "https://api.github.com$path"
}

# JSON 문자열에서 숫자 필드 하나 뽑기 (jq 가 있으면 jq, 없으면 grep/sed)
json_num() {
  local key="$1"
  if command -v jq >/dev/null 2>&1; then jq -r ".${key} // empty"
  else grep -o "\"${key}\"[[:space:]]*:[[:space:]]*[0-9]*" | head -1 | sed 's/.*://; s/[[:space:]]//g'; fi
}
