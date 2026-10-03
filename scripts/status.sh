#!/usr/bin/env bash
# 현재 환경에 설치된 스킬/도구 상태를 보여준다.
#   bash scripts/status.sh
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

info "skills installed (npx skills list)"
if command -v npx >/dev/null 2>&1; then
  npx -y skills list -g 2>/dev/null || warn "npx skills list failed"
  echo
  npx -y skills list 2>/dev/null || true
else
  warn "npx not found"
fi

echo
info "tools (manifest/tools.list)"
while IFS= read -r -u 3 line; do
  split_fields "$line"
  name="${FIELDS[0]}"; check="${FIELDS[1]}"
  if bash -c "$check" 2>/dev/null; then printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$name"
  else printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$name"; fi
done 3< <(manifest_lines "$TOOLS_LIST")

echo
info "skill directories"
for d in ~/.claude/skills ~/.codex/skills ~/.cursor/skills ~/.gemini/skills ~/.config/opencode/skills .claude/skills .agents/skills; do
  [ -d "$d" ] || continue
  cnt="$(find "$d" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  printf '  %-32s %s skill(s)\n' "$d" "$cnt"
done
