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

# ---- 옵션 -------------------------------------------------------------------
SCOPE_FLAG="-g"
AGENTS=()
TAG=""
DO_SKILLS=1
DO_TOOLS=1
DRY_RUN=0

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
    -h|--help)      usage; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  shift
done

run() {
  if [ "$DRY_RUN" = 1 ]; then printf '%s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"; return 0; fi
  printf '%s$ %s%s\n' "$C_DIM" "$*" "$C_RESET"
  "$@"
}

# ---- 사전 점검 --------------------------------------------------------------
command -v git  >/dev/null 2>&1 || die "git 이 필요합니다."
if [ "$DO_SKILLS" = 1 ] || [ "$DO_TOOLS" = 1 ]; then
  command -v node >/dev/null 2>&1 || die "node/npm 이 필요합니다. https://nodejs.org (18+)"
  command -v npx  >/dev/null 2>&1 || die "npx 가 필요합니다."
fi

info "ai_agent_setup bootstrap"
printf '    scope : %s\n' "$([ -n "$SCOPE_FLAG" ] && echo global || echo project)"
printf '    agents: %s\n' "$([ ${#AGENTS[@]} -gt 0 ] && echo "${AGENTS[*]}" || echo '(auto-detect)')"
printf '    tag   : %s\n' "${TAG:-(all)}"
[ "$DRY_RUN" = 1 ] && printf '    mode  : dry-run\n'

FAILED=()

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
    if ! run bash -c "$install"; then
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
    printf '  %s→%s %-40s %s\n' "$C_BOLD" "$C_RESET" "$src" "$desc"

    cmd=(npx -y skills add "$src" -y)
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
    fi
  done 3< <(manifest_lines "$SKILLS_LIST")
fi

# ---- 결과 -------------------------------------------------------------------
echo
if [ ${#FAILED[@]} -gt 0 ]; then
  error "finished with ${#FAILED[@]} failure(s):"
  printf '    - %s\n' "${FAILED[@]}"
  exit 1
fi
info "done. 확인: bash scripts/status.sh"
