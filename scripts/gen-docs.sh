#!/usr/bin/env bash
# README.md 의 "생성 구간"을 manifest 에서 만든다. 손으로 고치면 manifest 와 어긋나므로(스킬 표 13/23, 도구 표 13/21 로 어긋났던 적이 있다)
# 표와 숫자는 이 스크립트가 쓰고, validate.sh 가 --check 로 최신인지 확인한다.
#
#   bash scripts/gen-docs.sh            # README.md 의 생성 구간을 다시 쓴다
#   bash scripts/gen-docs.sh --check    # 최신이 아니면 실패 (README 는 수정하지 않는다)
#
# 생성 구간은 README.md 안의 이 표시로 구분한다:
#   <!-- BEGIN:generated:summary --> ... <!-- END:generated:summary -->   (숫자 요약과 core 구성)
#   <!-- BEGIN:generated:skills -->  ... <!-- END:generated:skills -->    (외부 스킬 소스 표)
#   <!-- BEGIN:generated:tools -->   ... <!-- END:generated:tools -->     (도구 표)
# 이 저장소의 로컬 스킬(skills/)은 설명을 한국어로 손으로 쓰되, 폴더가 README 에 빠지면 --check 가 실패한다.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

README="$REPO_ROOT/README.md"
MODE="write"
case "${1:-}" in
  --check) MODE="check" ;;
  "") ;;
  -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
  *) die "unknown option: $1" ;;
esac

md() { local s="$1"; s="${s//|/\\|}"; printf '%s' "$s"; }   # 표 셀 안의 | 이스케이프

gen_summary() {
  local n_src=0 n_named=0 n_wild=0 n_tools=0 line f s arr core_src=() core_tools=()
  while IFS= read -r line; do
    split_fields "$line"; n_src=$((n_src+1))
    if [ "${FIELDS[1]:-*}" = "*" ]; then n_wild=$((n_wild+1))
    else IFS=',' read -r -a arr <<<"${FIELDS[1]}"; n_named=$((n_named+${#arr[@]})); fi
    has_tag "${FIELDS[2]:-}" core && core_src+=("$(src_repo "${FIELDS[0]}")")
  done < <(manifest_lines "$SKILLS_LIST")
  while IFS= read -r line; do
    split_fields "$line"; n_tools=$((n_tools+1))
    has_tag "${FIELDS[3]:-}" core && core_tools+=("${FIELDS[0]}")
  done < <(manifest_lines "$TOOLS_LIST")
  local n_local=0
  for f in "$REPO_ROOT"/skills/*/SKILL.md; do [ -f "$f" ] && n_local=$((n_local+1)); done

  printf '> **이 저장소가 지금 관리하는 것** (manifest 에서 자동 생성):\n'
  printf '> 외부 스킬 소스 **%d개**(스킬을 이름으로 지정한 소스 %d개 — 합쳐 스킬 %d개 — + 스킬 전체를 받는 `*` 소스 %d개), 이 저장소가 직접 정의한 로컬 스킬 **%d개**, 도구 **%d개**.\n' \
    "$n_src" "$((n_src - n_wild))" "$n_named" "$n_wild" "$n_local" "$n_tools"
  printf '>\n'
  printf '> **`--tag core`(작은 세트)**: 스킬 소스 %s, 도구 %s. 로컬 스킬은 포함되지 않습니다.\n' \
    "$(printf '`%s`, ' "${core_src[@]}" | sed 's/, $//')" \
    "$(printf '`%s`, ' "${core_tools[@]}" | sed 's/, $//')"
}

gen_skills() {
  printf '| 저장소 | 설치 스킬 | 태그 | 설명 |\n|---|---|---|---|\n'
  local line repo names
  while IFS= read -r line; do
    split_fields "$line"
    repo="$(src_repo "${FIELDS[0]}")"
    names="${FIELDS[1]:-*}"; [ "$names" = "*" ] && names="전체" || names="$(printf '%s' "$names" | sed 's/,/, /g')"
    printf '| [%s](https://github.com/%s) | %s | %s | %s |\n' "$repo" "$repo" "$(md "$names")" "$(md "${FIELDS[2]:-}")" "$(md "${FIELDS[3]:-}")"
  done < <(manifest_lines "$SKILLS_LIST")
}

# 설치 명령에서 고정 버전을 뽑는다: uv/pip ==버전, npm/npx 패키지@버전, git 커밋, 릴리스 URL 의 버전 순서로 첫 번째.
pinned_version() {
  local ins="$1" v
  # '===' 같은 비교식에 걸리지 않게 앞이 '=' 가 아닌 '==' 만 본다. 릴리스 URL 의 버전을 40자리 hex(커밋 또는 sha256)보다 먼저 본다.
  v="$(printf '%s' "$ins" | grep -oE "(^|[^=])==[0-9][0-9A-Za-z.+-]*" | head -1 | sed -E 's/^.?==//')"
  [ -z "$v" ] && v="$(printf '%s' "$ins" | grep -oE "(npm install -g|npx -y) +(@[^/@ ]+/)?[^@/ ]+@[0-9][0-9A-Za-z.+-]*" | head -1 | sed -E 's/.*@//')"
  [ -z "$v" ] && v="$(printf '%s' "$ins" | grep -oE "/v?[0-9]+\.[0-9]+\.[0-9]+/" | head -1 | tr -d '/v')"
  [ -z "$v" ] && v="$(printf '%s' "$ins" | grep -oE "(@|checkout -q )[0-9a-f]{40}" | head -1 | grep -oE "[0-9a-f]{40}" | cut -c1-7 | sed 's/^/커밋 /')"
  printf '%s' "${v:-—}"
}

gen_tools() {
  printf '| 도구 | 고정 버전 | 태그 | 설명 |\n|---|---|---|---|\n'
  local line
  while IFS= read -r line; do
    split_fields "$line"
    printf '| `%s` | %s | %s | %s |\n' "${FIELDS[0]}" "$(md "$(pinned_version "${FIELDS[2]}")")" "$(md "${FIELDS[3]:-}")" "$(md "${FIELDS[4]:-}")"
  done < <(manifest_lines "$TOOLS_LIST")
}

# README 의 한 구간을 새 내용으로 바꾼 결과를 stdout 으로 낸다. 표시가 없으면 실패.
replace_block() {
  local name="$1" content_file="$2" in_file="$3"
  grep -q "<!-- BEGIN:generated:$name -->" "$in_file" && grep -q "<!-- END:generated:$name -->" "$in_file" \
    || die "README.md 에 <!-- BEGIN:generated:$name --> / <!-- END:generated:$name --> 표시가 없습니다."
  awk -v b="<!-- BEGIN:generated:$name -->" -v e="<!-- END:generated:$name -->" -v cf="$content_file" '
    $0 == b { print; while ((getline l < cf) > 0) print l; skip = 1; next }
    $0 == e { skip = 0 }
    !skip { print }
  ' "$in_file"
}

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cp "$README" "$tmp/cur.md"
for blk in summary skills tools; do
  "gen_$blk" > "$tmp/$blk.txt"
  replace_block "$blk" "$tmp/$blk.txt" "$tmp/cur.md" > "$tmp/next.md"
  mv "$tmp/next.md" "$tmp/cur.md"
done

# 로컬 스킬 폴더가 README 에 빠지지 않았는지
missing=()
for d in "$REPO_ROOT"/skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  n="$(basename "$d")"
  grep -q "\`$n\`" "$README" || missing+=("$n")
done
if [ ${#missing[@]} -gt 0 ]; then
  error "README.md 의 로컬 스킬 표에 빠진 스킬: ${missing[*]}"; exit 1
fi

if [ "$MODE" = "check" ]; then
  if ! diff -q "$README" "$tmp/cur.md" >/dev/null; then
    error "README.md 의 생성 구간이 manifest 와 다릅니다. 'bash scripts/gen-docs.sh' 를 실행해 다시 쓰세요."
    diff "$README" "$tmp/cur.md" | head -8 >&2 || true
    exit 1
  fi
  info "README.md 생성 구간이 manifest 와 일치합니다"
else
  if diff -q "$README" "$tmp/cur.md" >/dev/null; then info "README.md 는 이미 최신입니다"
  else cp "$tmp/cur.md" "$README"; info "README.md 를 갱신했습니다"; fi
fi
