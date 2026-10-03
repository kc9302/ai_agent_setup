#!/usr/bin/env bash
# 매니페스트에 등록된 스킬 저장소의 GitHub 별 수를 실시간으로 조회해 표로 보여준다.
#   bash scripts/stars.sh            # 별 수 내림차순
#   GITHUB_TOKEN=... bash scripts/stars.sh   # rate limit 완화
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

command -v curl >/dev/null 2>&1 || die "curl 이 필요합니다."

rows=()
failed=0
while IFS= read -r -u 3 line; do
  split_fields "$line"
  src="${FIELDS[0]}"; desc="${FIELDS[3]:-}"
  stars="$(gh_api "/repos/$src" 2>/dev/null | json_num stargazers_count || true)"
  [ -z "$stars" ] && { stars="?"; failed=1; }
  rows+=("$stars|$src|$desc")
done 3< <(manifest_lines "$SKILLS_LIST")

printf '%s%8s  %-40s %s%s\n' "$C_BOLD" "stars" "source" "description" "$C_RESET"
printf '%s\n' "${rows[@]}" | sort -t'|' -k1,1nr | while IFS='|' read -r stars src desc; do
  printf '%8s  %-40s %s\n' "$stars" "$src" "$desc"
done
printf '%s(as of %s)%s\n' "$C_DIM" "$(date -u +%Y-%m-%d)" "$C_RESET"
[ "$failed" = 1 ] && warn "'?' = GitHub API 조회 실패 (rate limit 또는 네트워크 제한). GITHUB_TOKEN 을 설정해 보세요."
