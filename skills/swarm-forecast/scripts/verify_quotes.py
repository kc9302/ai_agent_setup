#!/usr/bin/env python3
"""Check that a report's quotes and citations exist in the run's evidence.

usage: verify_quotes.py <run_dir> [report.md] [--no-notice]

Evidence: rounds/*.jsonl ("content" fields) and interviews/*.md.
Every blockquote paragraph in the report (lines starting with ">") is checked:
  - it must end with a "— speaker [id]" citation line;
  - the quoted text, with "…" as a wildcard, must appear in the content of one
    of the cited ids, with the pieces in order (case and whitespace
    insensitive);
  - every id in square brackets ([r03#2], [iv:a05]) must exist.
The report must also open with the standard notice (references/report-notice.md):
a line starting with "**Notice.**" within its first 15 non-empty lines. Pass
--no-notice to skip that check.
Exit status 1 if anything fails.
"""
import json
import re
import sys
from pathlib import Path


def norm(s):
    return re.sub(r"\s+", " ", s.replace("’", "'").replace("“", '"').replace("”", '"')).strip().lower()


def in_order(parts, text):
    pos = 0
    for p in parts:
        pos = text.find(p, pos)
        if pos < 0:
            return False
        pos += len(p)
    return True


def main(argv):
    argv = list(argv)
    need_notice = "--no-notice" not in argv
    argv = [a for a in argv if a != "--no-notice"]
    if not argv:
        sys.exit(__doc__)
    run = Path(argv[0])
    report = Path(argv[1]) if len(argv) > 1 else run / "report.md"
    by_id, ids = {}, set()
    for f in sorted((run / "rounds").glob("*.jsonl")):
        for line in f.read_text(encoding="utf-8").splitlines():
            if line.strip():
                r = json.loads(line)
                ids.add(r["id"])
                by_id[r["id"]] = norm(r.get("content") or "")
    for f in sorted((run / "interviews").glob("*.md")) if (run / "interviews").is_dir() else []:
        ids.add(f"iv:{f.stem}")
        by_id[f"iv:{f.stem}"] = norm(f.read_text(encoding="utf-8"))

    # facts cited as [F3] are checked against facts.md
    facts = set(re.findall(r"^(F\d+)\s*\|", (run / "facts.md").read_text(encoding="utf-8"), re.M)) if (run / "facts.md").exists() else set()

    lines = report.read_text(encoding="utf-8").splitlines()
    blocks, cur = [], []
    for ln in lines:
        if ln.lstrip().startswith(">"):
            cur.append(re.sub(r"^\s*>\s?", "", ln))
        elif cur:
            blocks.append(cur)
            cur = []
    if cur:
        blocks.append(cur)

    bad = 0
    head = [l for l in lines if l.strip()][:15]
    if need_notice and not any(l.startswith("**Notice.**") for l in head):
        bad += 1
        print("MISSING NOTICE: the report must open with the standard notice (references/report-notice.md)")
    for b in blocks:
        text = [x for x in b if x.strip()]
        cite = text[-1] if text and re.match(r"^\s*[—–-]{1,2}\s", text[-1]) else None
        body = " ".join(text[:-1] if cite else text)
        parts = [p for p in (norm(x) for x in re.split(r"…|\.\.\.", body)) if len(p) >= 8]
        cited = re.findall(r"\[([^\]]+)\]", cite or "")
        for i in cited:
            if i not in ids and i not in facts:
                bad += 1
                print(f"UNKNOWN ID {i!r} in citation: {cite.strip()[:80]}")
        if not cite or not cited:
            bad += 1
            print(f"QUOTE WITHOUT CITATION: {body[:100]}")
        elif not parts or not any(in_order(parts, by_id.get(i, "")) for i in cited):
            bad += 1
            print(f"QUOTE NOT IN CITED ID {cited}: {body[:100]}")
    for i in set(re.findall(r"\[(r\d+#\d+)\]", "\n".join(lines))):
        if i not in ids:
            bad += 1
            print(f"UNKNOWN ID {i!r}")
    print(f"{len(blocks)} quote block(s) checked, {bad} problem(s)")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main(sys.argv[1:])
