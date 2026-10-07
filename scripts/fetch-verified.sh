#!/usr/bin/env bash
# 스크립트를 받아 sha256 이 맞을 때만 실행한다. `curl … | sh` 처럼 받은 내용을 그대로 실행하지 않기 위한 것이다.
#
#   bash scripts/fetch-verified.sh <url> <sha256> [스크립트에 넘길 인자…]
#
# 환경변수는 그대로 실행되는 스크립트에 전달된다. 종료 코드:
#   0/그 외 : 실행한 스크립트의 종료 코드
#   3       : 내려받지 못함(네트워크·URL). 호출한 쪽이 다른 방법으로 대체할 수 있다
#   4       : 해시가 다름(내용이 바뀌었거나 변조). 실행하지 않는다. 대체 경로로 넘어가지 않는 것이 맞다
#   2       : 사용법 오류, 해시 도구 없음
set -u
url="${1:-}"; want="${2:-}"
[ -n "$url" ] && [ -n "$want" ] || { echo "usage: fetch-verified.sh <url> <sha256> [args…]" >&2; exit 2; }
shift 2
want="$(printf '%s' "$want" | tr 'A-F' 'a-f')"
case "$want" in *[!0-9a-f]*|"") echo "fetch-verified: sha256 형식이 아닙니다: $want" >&2; exit 2 ;; esac
[ "${#want}" = 64 ] || { echo "fetch-verified: sha256 은 64자리여야 합니다" >&2; exit 2; }

if command -v sha256sum >/dev/null 2>&1; then hasher=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then hasher=(shasum -a 256)
else echo "fetch-verified: sha256sum 또는 shasum 이 필요합니다" >&2; exit 2; fi

tmp="$(mktemp)" || exit 2
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$url" -o "$tmp" || { echo "fetch-verified: 내려받지 못했습니다: $url" >&2; exit 3; }
got="$("${hasher[@]}" "$tmp" | awk '{print $1}')"
if [ "$got" != "$want" ]; then
  echo "fetch-verified: sha256 이 다릅니다. 실행하지 않습니다." >&2
  echo "  url     : $url" >&2
  echo "  기대    : $want" >&2
  echo "  실제    : $got" >&2
  exit 4
fi
sh "$tmp" "$@"
