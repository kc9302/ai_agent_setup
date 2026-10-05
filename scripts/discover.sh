#!/usr/bin/env bash
# GitHub 에서 별이 많은 Agent Skills 저장소를 찾아, 아직 매니페스트에 없는 것만 보여준다.
# 새 스킬을 매니페스트에 추가할 후보를 고를 때 사용.
#
#   bash scripts/discover.sh                 # 기본 토픽으로 검색
#   bash scripts/discover.sh "archify"       # 키워드 검색
#   bash scripts/discover.sh --topic claude-skills
#   GITHUB_TOKEN=... bash scripts/discover.sh      # rate limit 완화 (권장)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

command -v curl >/dev/null 2>&1 || die "curl 이 필요합니다."
command -v jq   >/dev/null 2>&1 || die "discover.sh 는 jq 가 필요합니다."

LIMIT=30
TOPICS=(agent-skills claude-skills skill-md agentic-skills)
QUERY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --topic|-t) shift; TOPICS=("$1") ;;
    --limit|-n) shift; LIMIT="$1" ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) QUERY="$1" ;;
  esac
  shift
done

# 이미 매니페스트에 있는 source 목록
known="$(manifest_lines "$SKILLS_LIST" | while IFS= read -r l; do split_fields "$l"; _r="$(src_repo "${FIELDS[0]}")"; printf '%s\n' "${_r,,}"; done)"

urlencode() { jq -rn --arg s "$1" '$s|@uri'; }

results="$(
  if [ -n "$QUERY" ]; then
    q="$(urlencode "$QUERY in:name,description,readme SKILL.md")"
    gh_api "/search/repositories?q=$q&sort=stars&order=desc&per_page=$LIMIT"
  else
    for t in "${TOPICS[@]}"; do
      q="$(urlencode "topic:$t")"
      gh_api "/search/repositories?q=$q&sort=stars&order=desc&per_page=$LIMIT"
      sleep 1
    done
  fi | jq -c '.items[]? | {full_name, stargazers_count, description, pushed_at}'
)" || true
[ -n "$results" ] || die "GitHub API 에서 결과를 받지 못했습니다 (rate limit 또는 네트워크 제한). GITHUB_TOKEN 을 설정해 보세요."

printf '%s%8s  %-40s %-10s %s%s\n' "$C_BOLD" "stars" "repo" "pushed" "description" "$C_RESET"
printf '%s\n' "$results" \
  | jq -r '[.stargazers_count, .full_name, (.pushed_at|.[0:10]), (.description // "" | gsub("[\\n\\r|]"; " ") | .[0:70])] | @tsv' \
  | sort -t$'\t' -k1,1nr -u \
  | awk -F'\t' '!seen[$2]++' \
  | while IFS=$'\t' read -r stars repo pushed desc; do
      if printf '%s\n' "$known" | grep -qxF "${repo,,}"; then
        printf '%s%8s  %-40s %-10s %s (already in manifest)%s\n' "$C_DIM" "$stars" "$repo" "$pushed" "$desc" "$C_RESET"
      else
        printf '%8s  %-40s %-10s %s\n' "$stars" "$repo" "$pushed" "$desc"
      fi
    done

cat <<MSG

${C_DIM}추가하려면 manifest/skills.list 에 한 줄 추가:
  owner/repo | * | <tags> | <설명>
그 다음: bash scripts/validate.sh && bash bootstrap.sh${C_RESET}
MSG
