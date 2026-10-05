#!/usr/bin/env bash
# swarm-forecast 를 독립 저장소 형태로 내보낸다.
#   bash scripts/export-swarm-forecast.sh <빈 디렉터리>
# 결과: skills/swarm-forecast/ + README.md + LICENSE + tests/ + CI + CHANGELOG.
# 원본은 이 저장소의 skills/swarm-forecast/ 하나이고, 내보내기는 복사만 한다.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
dest="${1:-}"; [ -n "$dest" ] || die "사용법: $0 <빈 디렉터리>"
mkdir -p "$dest"
[ -z "$(ls -A "$dest")" ] || die "$dest 가 비어 있지 않습니다."
pk="$REPO_ROOT/packaging/swarm-forecast"
mkdir -p "$dest/skills"
cp -r "$REPO_ROOT/skills/swarm-forecast" "$dest/skills/"
cp -r "$pk/tests" "$pk/.github" "$dest/"
cp "$pk/README.md" "$pk/LICENSE" "$pk/CHANGELOG.md" "$pk/.gitignore" "$dest/"
find "$dest" -name __pycache__ -prune -exec rm -rf {} +
info "내보냄: $dest  (README 의 <owner> 와 LICENSE 의 저작권자를 확인하세요)"
