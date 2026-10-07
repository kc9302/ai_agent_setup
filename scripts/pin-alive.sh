#!/usr/bin/env bash
# 고정해 둔 것이 아직 받아지는지 확인한다. 업스트림이 저장소를 지우거나 force-push 로 커밋을 없애거나 패키지 버전을 내리면,
# 고정한 상태 그대로는 더 이상 설치되지 않는다. 그 일이 사용자가 설치하다 터지기 전에 알려 주는 점검이다 (설치는 하지 않는다).
#
#   bash scripts/pin-alive.sh                  # 스킬 소스 + 도구 전부
#   bash scripts/pin-alive.sh --skills         # 스킬 소스의 고정 커밋만 (git fetch)
#   bash scripts/pin-alive.sh --tools          # 도구만: npm 버전, PyPI 버전, 해시를 확인하는 설치 스크립트(내용이 그대로인지), git 커밋
#   bash scripts/pin-alive.sh --check-git <저장소 URL> <커밋>    # 한 개만 확인 (테스트용)
#
# 종료 코드 1 이면 받을 수 없는 것이 있다. "받아진다"는 지금 받을 수 있다는 뜻이지 앞으로도 그렇다는 보증이 아니다.
# 네트워크가 필요하다. 일시적인 네트워크 오류도 ✗ 로 나오므로, 실패하면 한 번 더 실행해 보고 판단한다.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

command -v git  >/dev/null 2>&1 || die "git 이 필요합니다."
command -v curl >/dev/null 2>&1 || die "curl 이 필요합니다."

dead=0; alive=0
ok()  { alive=$((alive+1)); printf '  %s✓%s %-8s %-34s %s\n' "$C_GREEN" "$C_RESET" "$1" "$2" "$3"; }
bad() { dead=$((dead+1));   printf '  %s✗%s %-8s %-34s %s\n' "$C_RED" "$C_RESET" "$1" "$2" "$3"; DEAD_LINES+=("$1 $2 $3"); }
DEAD_LINES=()

# 저장소가 그 커밋을 아직 내주는지 (skills CLI 가 하는 것과 같은 방식: 빈 저장소에서 그 커밋만 fetch)
git_has_commit() {
  local url="$1" sha="$2" d rc
  d="$(mktemp -d)" || return 2
  ( cd "$d" && git init -q . && GIT_TERMINAL_PROMPT=0 git fetch -q --depth 1 "$url" "$sha" >/dev/null 2>&1 )
  rc=$?; rm -rf "$d"; return $rc
}

check_skills() {
  info "스킬 소스의 고정 커밋 (manifest/skills.list)"
  local line src repo sha
  while IFS= read -r -u 3 line; do
    split_fields "$line"; src="${FIELDS[0]}"; repo="$(src_repo "$src")"; sha="$(src_ref "$src")"
    if [ -z "$sha" ]; then bad skill "$repo" "고정되지 않은 소스"; continue; fi
    if git_has_commit "https://github.com/$repo.git" "$sha"; then ok skill "$repo" "${sha:0:7}"; else bad skill "$repo" "${sha:0:7} 를 받을 수 없습니다 (저장소 삭제·이름 변경·커밋 제거?)"; fi
  done 3< <(manifest_lines "$SKILLS_LIST")
}

sha256_of() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }

check_tools() {
  info "도구의 고정 버전 (manifest/tools.list)"
  local line name ins spec pkg ver url want tmp got seen
  while IFS= read -r -u 3 line; do
    split_fields "$line"; name="${FIELDS[0]}"; ins="${FIELDS[2]}"; seen=0
    # npm / npx 패키지@버전
    while IFS= read -r spec; do
      [ -n "$spec" ] || continue; seen=1
      # npm 버전에 따라 없는 버전이 빈 출력으로 끝날 수 있어, 종료 코드와 함께 출력이 비었는지도 본다
      if [ -n "$(npm view "$spec" version 2>/dev/null)" ]; then ok npm "$name" "$spec"; else bad npm "$name" "$spec 을(를) 받을 수 없습니다"; fi
    done < <(printf '%s' "$ins" | grep -oE "(npm install -g|npx -y) +(@[^/@ ]+/)?[^@/ ]+@[0-9][0-9A-Za-z.+-]*" | sed -E 's/^(npm install -g|npx -y) +//' | sort -u)
    # PyPI 패키지==버전 (extras 는 뗀다)
    while IFS= read -r spec; do
      [ -n "$spec" ] || continue; seen=1
      pkg="${spec%%==*}"; pkg="${pkg%%\[*}"; ver="${spec##*==}"
      if curl -fsS -o /dev/null "https://pypi.org/pypi/$pkg/$ver/json" 2>/dev/null; then ok pypi "$name" "$pkg==$ver"; else bad pypi "$name" "$pkg==$ver 을(를) 받을 수 없습니다"; fi
    done < <(printf '%s' "$ins" | grep -oE "[A-Za-z0-9_.-]+(\[[^]]*\])?==[0-9][0-9A-Za-z.+-]*" | sort -u)
    # 해시를 확인하는 설치 스크립트: 지금도 같은 내용인가
    while read -r url want; do
      [ -n "$url" ] || continue; seen=1
      tmp="$(mktemp)"
      if curl -fsSL "$url" -o "$tmp" 2>/dev/null; then
        got="$(sha256_of "$tmp")"
        if [ "$got" = "$want" ]; then ok script "$name" "sha256 일치 (${want:0:12}…)"; else bad script "$name" "내용이 바뀌었습니다 (기대 ${want:0:12}…, 실제 ${got:0:12}…)"; fi
      else bad script "$name" "$url 을(를) 받을 수 없습니다"; fi
      rm -f "$tmp"
    done < <(printf '%s' "$ins" | grep -oE 'fetch-verified\.sh"? +[^ ]+ +[0-9a-f]{64}' | awk '{print $2, $3}')
    # git 커밋: git+https://…/x.git@<커밋>, 또는 git clone 한 저장소 + 40자리 커밋
    local gurl gsha
    gurl="$(printf '%s' "$ins" | grep -oE "https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git" | head -1)"
    gsha="$(printf '%s' "$ins" | grep -oE "[0-9a-f]{40}" | head -1)"
    if [ -n "$gurl" ] && [ -n "$gsha" ]; then
      seen=1
      if git_has_commit "$gurl" "$gsha"; then ok git "$name" "${gsha:0:7}"; else bad git "$name" "${gsha:0:7} 를 받을 수 없습니다 ($gurl)"; fi
    fi
    [ "$seen" = 1 ] || printf '  %s-%s %-8s %-34s %s\n' "$C_DIM" "$C_RESET" "-" "$name" "고정 대상 없음(다른 도구에 딸린 항목)"
  done 3< <(manifest_lines "$TOOLS_LIST")
}

MODE="all"
case "${1:-}" in
  --skills) MODE="skills" ;;
  --tools)  MODE="tools" ;;
  --check-git)
    [ $# -ge 3 ] || die "usage: pin-alive.sh --check-git <url> <sha>"
    if git_has_commit "$2" "$3"; then echo "alive"; exit 0; else echo "dead"; exit 1; fi ;;
  "") ;;
  -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) die "unknown option: $1" ;;
esac

[ "$MODE" = "tools" ] || check_skills
if [ "$MODE" != "skills" ]; then
  command -v npm >/dev/null 2>&1 || die "도구 점검에는 npm 이 필요합니다."
  check_tools
fi

echo
if [ "$dead" -gt 0 ]; then
  error "받을 수 없는 것 ${dead}건 (받아지는 것 ${alive}건):"
  printf '    - %s\n' "${DEAD_LINES[@]}"
  exit 1
fi
info "고정한 ${alive}건 모두 지금 받을 수 있습니다"
