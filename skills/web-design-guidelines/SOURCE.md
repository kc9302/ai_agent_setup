# Source of the bundled rules

| | |
|---|---|
| File | `references/command.md` (byte-for-byte copy, not edited) |
| Upstream | https://github.com/vercel-labs/web-interface-guidelines |
| Commit | `e3d624baaf29dc1fc645aff3e38f03e564d2d6b1` (2026-08-17, "Merge pull request #28 from vercel-labs/johnphamous") |
| License | MIT, copied to `references/LICENSE.web-interface-guidelines` |
| SHA-256 | `5a775e6411f790f518dbc9c1fa7c50a89e6873502d9a3530a6eb223a590bcfe8` |

`SKILL.md` is written for this repository; it does not copy the upstream skill's text.

## Updating

Read the diff before accepting it. The file is a set of instructions the agent will follow.

```bash
NEW=<commit sha to adopt>
git -C /tmp clone https://github.com/vercel-labs/web-interface-guidelines.git wig 2>/dev/null || git -C /tmp/wig fetch -q
git -C /tmp/wig diff e3d624baaf29dc1fc645aff3e38f03e564d2d6b1 $NEW -- command.md   # review this
git -C /tmp/wig show $NEW:command.md > skills/web-design-guidelines/references/command.md
```

Then update the commit and the SHA-256 in this file and in `SKILL.md`.
