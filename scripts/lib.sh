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

# ---- 소스 고정 ---------------------------------------------------------------
# skills.list 의 소스 필드는 'owner/repo#<40자리 커밋>' 형식으로 커밋에 고정한다.
# 고정하지 않으면 클론한 시점의 최신 코드가 설치돼 환경마다 달라진다.
# 설치기가 쓰는 skills CLI 는 manifest/skills-cli.version 의 버전으로 고정한다 (npx -y skills 는 최신판을 받아 환경마다 달라진다).
SKILLS_CLI="skills@$(grep -Ev '^[[:space:]]*(#|$)' "$MANIFEST_DIR/skills-cli.version" 2>/dev/null | head -1 | tr -d '[:space:]')"
case "$SKILLS_CLI" in skills@[0-9]*) ;; *) echo "[error] manifest/skills-cli.version 을 읽지 못했습니다 (예: 1.7.1)" >&2; exit 1 ;; esac

src_repo() { printf '%s' "${1%%#*}"; }
src_ref()  { case "$1" in *'#'*) printf '%s' "${1#*#}" ;; esac; }

# ---- 설치 결과 검증 -----------------------------------------------------------
# 매니페스트가 이름으로 지정한 스킬이 실제로 설치됐는지 `skills ls --json` 과 대조한다.
#
# 왜 필요한가: skills CLI 는 --skill 을 폴더 이름이 아니라 SKILL.md 의 name: 값으로 찾고,
# 일치하지 않는 이름은 오류 없이 건너뛴 채 종료 코드 0 으로 끝난다. 그래서 설치 명령의
# 성공 여부만으로는 "정의한 스킬이 전부 설치됐다"를 알 수 없다.
#
# 호출 전에 전역 배열을 채운다.
#   EXPECT_NAMES   : "owner/repo:스킬이름"  이 이름의 스킬이 설치돼 있어야 한다
#   EXPECT_SOURCES : "owner/repo"           '*' 로 받은 소스. 그 소스의 스킬이 1개 이상 있어야 한다
# 결과는 VERIFY_MISSING 배열에 담기고, 빠진 게 있으면 1 을 돌려준다.
# 확인 자체가 불가능하면(CLI 오류 등) 경고만 내고 0 을 돌려준다.
EXPECT_NAMES=(); EXPECT_SOURCES=(); VERIFY_MISSING=()
verify_installed_skills() {
  local scope="$1"; shift
  local -a agents=("$@") targets=()
  local a json rows pair repo name n_names=0
  VERIFY_MISSING=()
  if [ ${#agents[@]} -gt 0 ]; then targets=("${agents[@]}"); else targets=(""); fi
  for a in "${targets[@]}"; do
    local -a args=(ls --json)
    [ -n "$scope" ] && args+=("$scope")
    [ -n "$a" ] && args+=(-a "$(trim "$a")")
    if ! json="$(npx -y "$SKILLS_CLI" "${args[@]}" 2>/dev/null)"; then
      warn "설치 결과를 확인하지 못했습니다 (skills ls 실패)"; return 0
    fi
    # JSON 앞에 다른 출력이 섞여도 첫 '[' 부터 해석한다. 결과는 "이름<TAB>소스" 줄들.
    if ! rows="$(printf '%s' "$json" | node -e '
      let s=""; process.stdin.on("data",d=>s+=d).on("end",()=>{
        try { const a=JSON.parse(s.slice(s.indexOf("["))); for (const x of a) console.log(x.name+"\t"+(x.source||"")); }
        catch (e) { process.exit(3); }
      });' 2>/dev/null)"; then
      warn "설치 결과를 확인하지 못했습니다 (skills ls --json 해석 실패)"; return 0
    fi
    n_names=0
    for pair in "${EXPECT_NAMES[@]+"${EXPECT_NAMES[@]}"}"; do
      repo="${pair%%:*}"; name="${pair#*:}"
      n_names=$((n_names + 1))
      printf '%s\n' "$rows" | cut -f1 | grep -qxF -- "$name" \
        || VERIFY_MISSING+=("$name  ← $repo${a:+  (에이전트: $a)}")
    done
    for repo in "${EXPECT_SOURCES[@]+"${EXPECT_SOURCES[@]}"}"; do
      printf '%s\n' "$rows" | cut -f2 | grep -qixF -- "$repo" \
        || VERIFY_MISSING+=("(설치된 스킬 없음)  ← $repo${a:+  (에이전트: $a)}")
    done
  done
  if [ ${#VERIFY_MISSING[@]} -gt 0 ]; then
    error "정의한 스킬 중 설치되지 않은 것이 있습니다 (${#VERIFY_MISSING[@]}건):"
    printf '    - %s\n' "${VERIFY_MISSING[@]}" >&2
    return 1
  fi
  printf '  %s✓%s 이름으로 지정한 스킬 %d개, 와일드카드 소스 %d개 모두 설치됨\n' \
    "$C_GREEN" "$C_RESET" "$n_names" "${#EXPECT_SOURCES[@]}"
  return 0
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

# ---- WSL 안전장치 -----------------------------------------------------------
# PowerShell 에서 `bash` 를 치면 Git Bash 가 아니라 WSL 의 bash.exe 가 실행될 수 있다. 그러면 스킬이
# Windows 의 사용자 폴더가 아니라 WSL 안의 $HOME 에 설치된다. WSL 이고, WSL 홈에는 Claude Code 설정이
# 없는데 Windows 쪽에는 있으면 사용자가 Windows 를 의도했을 가능성이 높으므로 설치 전에 멈춘다.
# 테스트용: AI_SETUP_WINDOWS_CLAUDE_GLOB 로 Windows 쪽 .claude 위치 패턴을 바꿀 수 있다.
is_wsl() { [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; }

# 사용법: wsl_guard <허용(0|1)>. 멈춰야 하면 1 을 돌려준다.
wsl_guard() {
  local allow="${1:-0}" glob="${AI_SETUP_WINDOWS_CLAUDE_GLOB:-/mnt/*/Users/*/.claude}" d
  local -a win=()
  is_wsl || return 0
  for d in $glob; do [ -d "$d" ] && win+=("$d"); done
  printf '    wsl   : WSL 에서 실행 중 — 설치 위치는 WSL 의 %s 입니다 (Windows 사용자 폴더 아님)\n' "$HOME"
  if [ ! -d "$HOME/.claude" ] && [ ${#win[@]} -gt 0 ] && [ "$allow" != 1 ]; then
    error "WSL 의 홈($HOME)에는 Claude Code 설정(.claude)이 없고, Windows 쪽에는 있습니다:"
    printf '      %s\n' "${win[@]}" >&2
    cat >&2 <<'MSG'
    Windows 의 Claude Code 에 설치하려던 것이라면, WSL 이 아니라 Windows 에서 실행하세요:
      PowerShell :  node scripts\install-skills.mjs
      PowerShell 에서 도구까지 설치(Git Bash 지정) :  & "$env:ProgramFiles\Git\bin\bash.exe" bootstrap.sh
    WSL 안에 설치하는 것이 맞다면 --wsl 을 붙여 다시 실행하세요:  bash bootstrap.sh --wsl
MSG
    return 1
  fi
  return 0
}
