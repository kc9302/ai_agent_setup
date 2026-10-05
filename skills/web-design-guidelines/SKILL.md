---
name: web-design-guidelines
description: Review UI code against the Vercel Web Interface Guidelines (accessibility, forms, focus, animation, typography, performance, dark mode, i18n). Use when asked to "review my UI", "check accessibility", "audit design", "review UX", "check my site against best practices", or in Korean "UI 리뷰", "접근성 점검", "UX 검토". Rules are bundled with this skill at a pinned version; nothing is fetched from the network.
---

# web-design-guidelines (pinned copy)

Review the given files for compliance with the Web Interface Guidelines.

The rules live in this skill's own folder, not on the network:

- `references/command.md` — the full rule list **and** the required output format.
  Its path resolves against the directory that contains this `SKILL.md`.
- The text is a verbatim copy of `vercel-labs/web-interface-guidelines` `command.md`
  at commit `e3d624baaf29dc1fc645aff3e38f03e564d2d6b1` (MIT, see
  `references/LICENSE.web-interface-guidelines`). Provenance and how to update it:
  `SOURCE.md`.

## Why a bundled copy

The upstream skill (`vercel-labs/agent-skills` → `web-design-guidelines`) downloads
`command.md` from the `main` branch every time it runs. Then the rules, and the
instructions the agent follows, change whenever upstream changes, and they differ from
one machine or day to the next. This copy keeps every environment on identical rules.
Do **not** fetch the upstream file during a review; use the bundled one.

## Procedure

1. Read `references/command.md` completely. In it, `$ARGUMENTS` stands for the files or
   glob the user wants reviewed.
2. Take the files from the user's request. If none were given, ask which files or pattern to review.
3. Read those files and check them against every rule in `references/command.md`.
4. Output the findings in the terse `file:line` format that `references/command.md` specifies.
   Do not invent rules that are not in the bundled file.
