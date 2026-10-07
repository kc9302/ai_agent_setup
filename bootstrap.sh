#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# bootstrap.sh — 이 저장소의 매니페스트에 적힌 스킬과 오픈소스 도구를 현재 환경에 설치한다.
#
#   bash bootstrap.sh                 # 전역(-g) 으로 모든 스킬 + 도구 설치
#   bash bootstrap.sh --project       # 현재 프로젝트 디렉터리에만 스킬 설치
#   bash bootstrap.sh --agent claude-code --agent codex   # 특정 에이전트에만
#   bash bootstrap.sh --tag core      # 태그가 core 인 항목만
#   bash bootstrap.sh --skills-only | --tools-only
#   bash bootstrap.sh --dry-run       # 실행할 명령만 출력
#   bash bootstrap.sh --profile minimal   # 작은 세트: 스킬만(core 태그), 도구·MCP·curl|sh 없음. 처음 받는 사람의 첫 명령
#   bash bootstrap.sh --diff          # 설치하지 않고, 이미 가진 스킬과 겹치는/덮어쓸 것을 미리 보여준다 (Node 필요)
#   bash bootstrap.sh --wsl           # WSL 안에 설치하는 것이 맞을 때 (WSL 홈에 .claude 가 없고 Windows 쪽에만 있으면 기본은 멈춘다)
#
# 스킬은 skills.list 에 적힌 커밋에 고정해 설치하고(모든 환경에서 같은 내용), 설치가 끝나면
# 정의한 스킬이 실제로 설치됐는지 확인한다(빠진 게 있으면 실패로 보고).
#
# 클론 없이 바로 실행:
#   curl -fsSL https://raw.githubusercontent.com/kc9302/ai_agent_setup/main/bootstrap.sh | bash
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_SLUG="${AI_SETUP_REPO:-kc9302/ai_agent_setup}"
REPO_REF="${AI_SETUP_REF:-main}"

# curl | bash 로 실행되면 저장소가 없으므로 임시로 클론한다.
if [ -z "${BASH_SOURCE[0]:-}" ] || [ ! -f "$(dirname "${BASH_SOURCE[0]}")/scripts/lib.sh" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "==> cloning $REPO_SLUG@$REPO_REF into $tmp"
  git clone --quiet --depth 1 --branch "$REPO_REF" "https://github.com/$REPO_SLUG.git" "$tmp/repo"
  exec bash "$tmp/repo/bootstrap.sh" "$@"
fi

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib.sh"
# tools.list 의 install/check 가 이 저장소의 보조 스크립트(scripts/fetch-verified.sh)를 부를 때 쓴다.
export AI_SETUP_ROOT="$REPO_ROOT"
# skills CLI 와 도구가 쓰는 git 이 줄바꿈을 바꾸지 않게 한다. Windows 의 Git 기본값(core.autocrlf=true)이면 받은 스킬·스크립트가 CRLF 가 되어
# Linux·맥과 다른 바이트로 설치되고 .sh 는 bash 에서 깨진다. 환경변수 설정은 전역 git 설정보다 우선한다.
_gc="${GIT_CONFIG_COUNT:-0}"
export "GIT_CONFIG_KEY_${_gc}=core.autocrlf" "GIT_CONFIG_VALUE_${_gc}=false" "GIT_CONFIG_COUNT=$((_gc + 1))"
unset _gc

# ---- 옵션 -------------------------------------------------------------------
SCOPE_FLAG="-g"
AGENTS=()
TAG=""
DO_SKILLS=1
DO_TOOLS=1
DRY_RUN=0
ALLOW_WSL="${AI_SETUP_ALLOW_WSL:-0}"
PROFILE="full"
DIFF=0

# 환경변수로도 에이전트 지정 가능: AI_SETUP_AGENTS="claude-code,codex"
if [ -n "${AI_SETUP_AGENTS:-}" ]; then
  IFS=',' read -r -a AGENTS <<<"$AI_SETUP_AGENTS"
fi

usage() { sed -n '2,/^# ───.*$/p' "$0" | sed -n '2,$p' | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --project)      SCOPE_FLAG="" ;;
    --global|-g)    SCOPE_FLAG="-g" ;;
    --agent|-a)     shift; AGENTS+=("$1") ;;
    --tag|-t)       shift; TAG="$1" ;;
    --skills-only)  DO_TOOLS=0 ;;
    --tools-only)   DO_SKILLS=0 ;;
    --dry-run|-n)   DRY_RUN=1 ;;
    --wsl)          ALLOW_WSL=1 ;;
    --profile)      shift; PROFILE="${1:-}" ;;
    --diff)         DIFF=1 ;;
    -h|--help)      usage; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

case "$PROFILE" in
  full) ;;
  minimal)
    # 작은 세트: 스킬만, core 태그. 도구·MCP 등록·curl|sh 가 없고 관리자 권한이 필요 없다. 이 저장소의 로컬 스킬(skills/)은 core 태그가 없어 포함되지 않는다.
    [ -z "$TAG" ] || die "--profile minimal 은 --tag 와 함께 쓸 수 없습니다 (minimal 은 core 태그)"
    [ "$DO_SKILLS" = 1 ] || die "--profile minimal 은 --tools-only 와 함께 쓸 수 없습니다"
    DO_TOOLS=0; TAG="core" ;;
  *) die "알 수 없는 프로필: ${PROFILE:-(빈 값)} (full | minimal)" ;;
esac

# --diff 는 설치하지 않는다. 기존 스킬과의 겹침은 skills ls --json 이 필요해 Node 설치기가 맡는다.
if [ "$DIFF" = 1 ]; then
  dargs=(--diff)
  [ -n "$SCOPE_FLAG" ] || dargs+=(--project)
  [ -z "$TAG" ] || dargs+=(--tag "$TAG")
  [ "$PROFILE" = "full" ] || dargs+=(--profile "$PROFILE")
  for a in "${AGENTS[@]+"${AGENTS[@]}"}"; do dargs+=(--agent "$(trim "$a")"); done
  command -v node >/dev/null 2>&1 || die "--diff 는 node 가 필요합니다. https://nodejs.org (22.20+)"
  exec node "$(dirname "${BASH_SOURCE[0]}")/scripts/install-skills.mjs" "${dargs[@]}"
fi

run() {
  if [ "$DRY_RUN" = 1 ]; then printf '%s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"; return 0; fi
  printf '%s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"
  "$@"
}

# ---- 사전 점검 --------------------------------------------------------------
command -v git  >/dev/null 2>&1 || die "git 이 필요합니다."
if [ "$DO_SKILLS" = 1 ] || [ "$DO_TOOLS" = 1 ]; then
  command -v node >/dev/null 2>&1 || die "node/npm 이 필요합니다. https://nodejs.org (22.20+)"
  command -v npx  >/dev/null 2>&1 || die "npx 가 필요합니다."
  # skills CLI(1.5.2x 이후)는 Node 22.20+ 를 요구한다. 더 낮으면 `npx -y skills` 가 조용히 옛 버전(1.5.18)으로 내려가
  # 고정 커밋 설치가 전부 실패한다. 스킬 단계가 있을 때만 확인하고, --dry-run 은 경고만 한다.
  if [ "$DO_SKILLS" = 1 ] && ! node -e 'const [a,b]=process.versions.node.split(".").map(Number);process.exit(a>22||(a===22&&b>=20)?0:1)' 2>/dev/null; then
    nmsg="Node.js 22.20 이상이 필요합니다 (현재 $(node -v)). skills CLI 최신판이 이를 요구하고, 더 낮은 Node 에서는 npx 가 조용히 옛 버전(1.5.18)을 받아 고정 커밋 설치가 모두 실패합니다. https://nodejs.org"
    if [ "$DRY_RUN" = 1 ]; then warn "$nmsg"; else die "$nmsg"; fi
  fi
fi

info "ai_agent_setup bootstrap"
printf '    scope : %s\n' "$([ -n "$SCOPE_FLAG" ] && echo global || echo project)"
printf '    agents: %s\n' "$([ ${#AGENTS[@]} -gt 0 ] && echo "${AGENTS[*]}" || echo '(auto-detect)')"
printf '    tag   : %s\n' "${TAG:-(all)}"
printf '    profile: %s\n' "$PROFILE"
if [ "$PROFILE" = "minimal" ]; then
  printf '    minimal: 스킬만 설치합니다. 도구·MCP 서버 등록·curl|sh 는 하지 않고 관리자 권한이 필요 없습니다. 기존에 같은 이름의 스킬이 있으면 덮어쓰므로 먼저 `bash bootstrap.sh --profile minimal --diff` 로 확인할 수 있습니다.\n'
fi
[ "$DRY_RUN" = 1 ] && printf '    mode  : dry-run\n'

# Windows(Git Bash/MSYS/Cygwin)에서도 도구는 시도한다(실제로 대부분 설치됨). 조건이 안 맞는 도구(graft 네이티브 빌드,
# im-not-ai 심볼릭 링크 등)는 각 항목이 사유를 밝히고 건너뛰거나 경고만 남긴다.
case "${AI_SETUP_UNAME:-$(uname -s 2>/dev/null)}" in
  MINGW*|MSYS*|CYGWIN*) info "Windows 환경(Git Bash): 일부 도구는 빌드 도구나 심볼릭 링크가 없으면 건너뜁니다." ;;
esac

# WSL 이면 어디에 설치되는지 알리고, Windows 를 의도했을 가능성이 높으면 멈춘다 (--dry-run 은 경고만).
if ! wsl_guard "$ALLOW_WSL"; then
  [ "$DRY_RUN" = 1 ] || exit 2
fi

FAILED=()
SKIPPED=()
# tools.list 의 install 이 이 종료 코드(EX_TEMPFAIL)로 끝나면 '선행 조건 미충족으로 건너뜀'이며 실패가 아니다.
SKIP_EXIT=75

# ---- 도구 -------------------------------------------------------------------
if [ "$DO_TOOLS" = 1 ]; then
  info "installing tools from manifest/tools.list"
  while IFS= read -r -u 3 line; do
    split_fields "$line"
    name="${FIELDS[0]}"; check="${FIELDS[1]}"; install="${FIELDS[2]}"; tags="${FIELDS[3]:-}"; desc="${FIELDS[4]:-}"
    has_tag "$tags" "$TAG" || continue
    if bash -c "$check" 2>/dev/null; then
      printf '  %s✓%s %-16s already installed\n' "$C_GREEN" "$C_RESET" "$name"
      continue
    fi
    printf '  %s→%s %-16s %s\n' "$C_BOLD" "$C_RESET" "$name" "$desc"
    rc=0; run bash -c "$install" || rc=$?
    if [ "$rc" = "$SKIP_EXIT" ]; then
      # 선행 조건(예: Node 버전)이 맞지 않아 설치할 수 없는 도구. 실패가 아니라 건너뜀으로 보고한다.
      printf '  %s↷%s %-16s 건너뜀 (위 사유 참고)\n' "$C_YELLOW" "$C_RESET" "$name"; SKIPPED+=("$name")
    elif [ "$rc" != 0 ]; then
      warn "failed: $name"; FAILED+=("tool:$name")
    fi
  done 3< <(manifest_lines "$TOOLS_LIST")
fi

# ---- 스킬 -------------------------------------------------------------------
if [ "$DO_SKILLS" = 1 ]; then
  info "installing skills from manifest/skills.list"
  while IFS= read -r -u 3 line; do
    split_fields "$line"
    src="${FIELDS[0]}"; skills="${FIELDS[1]:-*}"; tags="${FIELDS[2]:-}"; desc="${FIELDS[3]:-}"
    has_tag "$tags" "$TAG" || continue
    printf '  %s→%s %-40s %s\n' "$C_BOLD" "$C_RESET" "$(src_repo "$src")" "$desc"

    # $src 는 'owner/repo#<커밋>' 형식 그대로 넘긴다. CLI 가 그 커밋의 내용을 받는다.
    cmd=(npx -y "$SKILLS_CLI" add "$src" -y)
    [ -n "$SCOPE_FLAG" ] && cmd+=("$SCOPE_FLAG")
    for a in "${AGENTS[@]+"${AGENTS[@]}"}"; do cmd+=(-a "$(trim "$a")"); done
    # 저장소 루트에 SKILL.md 가 있으면 CLI 가 하위 스킬을 못 찾는다. 태그 full-depth 로 하위 디렉터리까지 탐색.
    has_tag "$tags" full-depth && cmd+=(--full-depth)
    if [ "$skills" = "*" ]; then
      cmd+=(--skill '*')
    else
      IFS=',' read -r -a arr <<<"$skills"
      for s in "${arr[@]}"; do cmd+=(--skill "$(trim "$s")"); done
    fi
    if ! run "${cmd[@]}"; then
      warn "failed: $src"; FAILED+=("skill:$src")
    elif [ "$skills" = "*" ]; then
      EXPECT_SOURCES+=("$(src_repo "$src")")
    else
      for s in "${arr[@]}"; do EXPECT_NAMES+=("$(src_repo "$src"):$(trim "$s")"); done
    fi
  done 3< <(manifest_lines "$SKILLS_LIST")

  # 이 저장소가 직접 정의한 스킬(skills/). 클론한 저장소에서 바로 설치하므로 항상 이 체크아웃과 같다.
  # (로컬 경로 설치는 파일을 복사하므로 임시 클론이 지워져도 남는다.)
  if has_tag "local" "$TAG"; then
    local_names=()
    for f in "$REPO_ROOT"/skills/*/SKILL.md; do
      [ -f "$f" ] || continue
      n="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d '\r"'"'")"
      [ -n "$n" ] && local_names+=("$n")
    done
    if [ ${#local_names[@]} -gt 0 ]; then
      info "installing this repository's own skills (skills/)"
      printf '  %s→%s %-40s %s\n' "$C_BOLD" "$C_RESET" "(local) $REPO_SLUG" "${local_names[*]}"
      cmd=(npx -y "$SKILLS_CLI" add "$REPO_ROOT" -y)
      [ -n "$SCOPE_FLAG" ] && cmd+=("$SCOPE_FLAG")
      for a in "${AGENTS[@]+"${AGENTS[@]}"}"; do cmd+=(-a "$(trim "$a")"); done
      for n in "${local_names[@]}"; do cmd+=(--skill "$n"); done
      if ! run "${cmd[@]}"; then
        warn "failed: local skills"; FAILED+=("skill:local")
      else
        for n in "${local_names[@]}"; do EXPECT_NAMES+=("local:$n"); done
        if [ "$DRY_RUN" != 1 ] && [ "$SCOPE_FLAG" = "-g" ]; then
          printf '  %s참고:%s 위 요약의 "✗ … PromptScript: PromptScript does not support global skill installation" 줄은 정상입니다(전역 설치를 지원하지 않는 에이전트를 건너뛴다는 skills CLI 안내). 결과에는 영향이 없습니다.\n' "$C_DIM" "$C_RESET"
        fi
      fi
    fi
  fi

  # 설치 명령이 성공해도 일부 스킬이 조용히 빠질 수 있으므로, 정의한 스킬이 실제로 있는지 확인한다.
  if [ "$DRY_RUN" != 1 ] && { [ ${#EXPECT_NAMES[@]} -gt 0 ] || [ ${#EXPECT_SOURCES[@]} -gt 0 ]; }; then
    info "verifying installed skills"
    if ! verify_installed_skills "$SCOPE_FLAG" "${AGENTS[@]+"${AGENTS[@]}"}"; then
      for m in "${VERIFY_MISSING[@]}"; do FAILED+=("skill-missing: $m"); done
    fi
  fi
fi

# ---- 결과 -------------------------------------------------------------------
echo
if [ ${#SKIPPED[@]} -gt 0 ]; then
  info "건너뛴 도구 ${#SKIPPED[@]}개 (선행 조건 미충족, 실패 아님): ${SKIPPED[*]}"
  printf '    조건을 갖춘 뒤 bash bootstrap.sh --tools-only 를 다시 실행하면 설치됩니다.\n'
fi
if [ ${#FAILED[@]} -gt 0 ]; then
  error "finished with ${#FAILED[@]} failure(s):"
  printf '    - %s\n' "${FAILED[@]}"
  exit 1
fi
info "done. 확인: bash scripts/status.sh"
