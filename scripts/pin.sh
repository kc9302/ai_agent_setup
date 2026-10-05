#!/usr/bin/env bash
# skills.list 의 스킬 소스를 커밋에 고정하거나 갱신한다.
#
#   bash scripts/pin.sh                          # 현재 고정과 upstream 최신 커밋을 비교해 보여준다 (수정 없음)
#   bash scripts/pin.sh --fill                   # 고정되지 않은 소스를 upstream 최신 커밋으로 고정
#   bash scripts/pin.sh --update                 # 모든 소스를 upstream 최신 커밋으로 올린다
#   bash scripts/pin.sh --update owner/repo ...  # 지정한 소스만 올린다
#
# 소스를 'owner/repo#<40자리 커밋>' 으로 적어 두면 bootstrap.sh 가 그 커밋의 내용을 설치한다.
# 고정하지 않으면 클론한 시점의 최신 코드가 설치돼 환경마다 달라진다.
#
# ⚠ 커밋을 올릴 때는 변경 내용을 검토한다. 이 스크립트는 비교 링크를 출력한다.
#   (스킬은 에이전트에게 지시문을 주는 코드이므로 올린 내용을 읽지 않고 받아들이지 않는다.)
# 네트워크는 `git ls-remote` 만 쓴다 (GitHub API 불필요).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

MODE="show"
TARGETS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --fill)   MODE="fill" ;;
    --update) MODE="update" ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) TARGETS+=("${1,,}") ;;
  esac
  shift
done

command -v git >/dev/null 2>&1 || die "git 이 필요합니다."

upstream_head() { git ls-remote "https://github.com/$1.git" HEAD 2>/dev/null | cut -c1-40; }

# skills.list 안의 한 소스의 고정 커밋을 바꿔 쓴다. 앞뒤 공백과 나머지 필드는 그대로 둔다.
rewrite_pin() {
  local repo="$1" sha="$2" tmp
  tmp="$(mktemp)"
  awk -v repo="$repo" -v sha="$sha" '
    /^[[:space:]]*(#|$)/ { print; next }
    {
      n = index($0, "|")
      if (n == 0) { print; next }
      head = substr($0, 1, n - 1); rest = substr($0, n)
      h = head; sub(/[[:space:]]+$/, "", h)
      pad = substr(head, length(h) + 1)
      base = h; sub(/#.*/, "", base)
      if (tolower(base) == tolower(repo)) { print base "#" sha pad rest } else { print }
    }' "$SKILLS_LIST" >"$tmp"
  cat "$tmp" >"$SKILLS_LIST"
  rm -f "$tmp"
}

wanted() {  # TARGETS 가 비어 있으면 모두, 아니면 목록에 있는 것만
  [ ${#TARGETS[@]} -eq 0 ] && return 0
  local t; for t in "${TARGETS[@]}"; do [ "$t" = "${1,,}" ] && return 0; done
  return 1
}

printf '%s%-44s %-9s %-9s %s%s\n' "$C_BOLD" "source" "pinned" "upstream" "status" "$C_RESET"
changed=0; unpinned=0; behind=0; failed=0
while IFS= read -r -u 3 line; do
  split_fields "$line"
  src="${FIELDS[0]}"; repo="$(src_repo "$src")"; ref="$(src_ref "$src")"
  head="$(upstream_head "$repo")"
  if [ -z "$head" ]; then
    printf '%-44s %-9s %-9s %s\n' "$repo" "${ref:0:7}" "?" "${C_RED}upstream 조회 실패${C_RESET}"; failed=1; continue
  fi
  if [ -z "$ref" ]; then
    status="${C_YELLOW}고정 안 됨${C_RESET}"; unpinned=$((unpinned + 1))
  elif [ "$ref" = "$head" ]; then
    status="${C_GREEN}최신${C_RESET}"
  else
    status="${C_YELLOW}뒤처짐${C_RESET}  https://github.com/$repo/compare/${ref:0:12}...${head:0:12}"; behind=$((behind + 1))
  fi
  printf '%-44s %-9s %-9s %s\n' "$repo" "${ref:0:7}" "${head:0:7}" "$status"
  if wanted "$repo"; then
    if { [ "$MODE" = fill ] && [ -z "$ref" ]; } || { [ "$MODE" = update ] && [ "$ref" != "$head" ]; }; then
      rewrite_pin "$repo" "$head"; changed=$((changed + 1))
    fi
  fi
done 3< <(manifest_lines "$SKILLS_LIST")

echo
case "$MODE" in
  show)   [ "$unpinned" -gt 0 ] && warn "고정되지 않은 소스 ${unpinned}개 → bash scripts/pin.sh --fill"
          [ "$behind" -gt 0 ] && printf '    upstream 이 앞선 소스 %d개 (올리려면 변경 내용을 검토한 뒤 --update)\n' "$behind" || true ;;
  *)      info "${changed}개 소스의 고정 커밋을 바꿨습니다. git diff manifest/skills.list 로 확인하고 bash scripts/validate.sh 를 통과시키세요." ;;
esac
[ "$failed" = 1 ] && warn "일부 소스의 upstream 조회에 실패했습니다 (네트워크 제한 또는 저장소 이동)."
exit 0
