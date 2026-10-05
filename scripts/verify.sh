#!/usr/bin/env bash
# 매니페스트가 정의한 스킬이 이 환경에 모두 설치돼 있는지 확인한다 (설치는 하지 않는다).
#
#   bash scripts/verify.sh                      # 전역(-g) 설치 기준
#   bash scripts/verify.sh --project            # 현재 프로젝트 기준
#   bash scripts/verify.sh --agent claude-code  # 특정 에이전트 기준 (여러 번 가능)
#   bash scripts/verify.sh --tag core           # 태그가 core 인 소스만
#
# 확인 대상: skills.list 가 이름으로 지정한 스킬, '*' 로 받는 소스(스킬이 1개 이상 있어야 함),
# 이 저장소의 skills/ 가 정의한 스킬. 도구(tools.list)가 설치하는 스킬은 각 도구의 check 로 확인한다 (status.sh).
# 빠진 것이 있으면 종료 코드 1.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SCOPE_FLAG="-g"; AGENTS=(); TAG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project)    SCOPE_FLAG="" ;;
    --global|-g)  SCOPE_FLAG="-g" ;;
    --agent|-a)   shift; AGENTS+=("$1") ;;
    --tag|-t)     shift; TAG="$1" ;;
    -h|--help)    sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  shift
done
command -v npx >/dev/null 2>&1 || die "npx 가 필요합니다."
command -v node >/dev/null 2>&1 || die "node 가 필요합니다."

while IFS= read -r -u 3 line; do
  split_fields "$line"
  src="${FIELDS[0]}"; skills="${FIELDS[1]:-*}"; tags="${FIELDS[2]:-}"
  has_tag "$tags" "$TAG" || continue
  if [ "$skills" = "*" ]; then
    EXPECT_SOURCES+=("$(src_repo "$src")")
  else
    IFS=',' read -r -a arr <<<"$skills"
    for s in "${arr[@]}"; do EXPECT_NAMES+=("$(src_repo "$src"):$(trim "$s")"); done
  fi
done 3< <(manifest_lines "$SKILLS_LIST")

if has_tag "local" "$TAG"; then
  for f in "$REPO_ROOT"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    n="$(sed -n 's/^name:[[:space:]]*//p' "$f" | head -1 | tr -d '\r"'"'")"
    [ -n "$n" ] && EXPECT_NAMES+=("local:$n")
  done
fi

info "verifying installed skills ($([ -n "$SCOPE_FLAG" ] && echo global || echo project), agents: ${AGENTS[*]:-all})"
verify_installed_skills "$SCOPE_FLAG" "${AGENTS[@]+"${AGENTS[@]}"}"
