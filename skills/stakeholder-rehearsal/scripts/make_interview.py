#!/usr/bin/env python3
"""Build an interview prompt for one agent after a run.

usage: make_interview.py <run_dir> <agent id> "<question 1>" ["<question 2>" ...]

Writes interviews/<id>.prompt.md: the agent's persona, everything it did in the
run (with the text of the posts it acted on), and the questions. The agent is
told to write its answers to interviews/<id>.md, which verify_quotes.py treats
as evidence under the id iv:<id>. Give the sub-agent only:
"Read <abs path>/interviews/<id>.prompt.md and follow it exactly."
"""
import json
import sys
from pathlib import Path


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    run, aid, questions = Path(argv[0]).resolve(), argv[1], argv[2:]
    rows = []
    for f in sorted((run / "rounds").glob("*.jsonl")):
        rows += [json.loads(l) for l in f.read_text(encoding="utf-8").splitlines() if l.strip()]
    by_id = {r["id"]: r for r in rows}
    persona = "\n".join((run / "cast" / f"{aid}.md").read_text(encoding="utf-8").strip().splitlines()[1:]).strip()
    hist = []
    for r in rows:
        if r["agent"] != aid:
            continue
        t = by_id.get(r.get("target"))
        on = f' on {t["name"]}\'s post [{t["id"]}] "{t["content"]}"' if t and t.get("content") else ""
        hist.append(f'{r["sim_time"]} {r["action"]}{on}' + (f' [{r["id"]}]: "{r["content"]}"' if r.get("content") else ""))
    out = run / "interviews" / f"{aid}.md"
    qs = "\n".join(f"{i}. {q}" for i, q in enumerate(questions, 1))
    packet = f"""You are being interviewed after a rehearsal of a real situation in which you took part. Answer in character, in plain text, in the first person. Do not use any tools except Write, and do not mention being an AI.

== WHO YOU ARE ==
{persona}

== WHAT YOU DID DURING THE EPISODE (in order) ==
{chr(10).join(hist) or "nothing"}

== OTHER POSTS IN THE EPISODE (all of them, for reference) ==
{chr(10).join(f'[{r["id"]}] {r["name"]}: "{r["content"]}"' for r in rows if r["action"] in ("post", "quote", "comment") and r.get("content"))}

== QUESTIONS ==
{qs}

Answer each question in 2-4 sentences, honestly for this participant, including what you did not notice or chose to ignore. Use the Write tool to create {out} with this layout and nothing else:
Q1: <question>
A1: <answer>
Q2: ...
Then reply with the single word: done.
"""
    (run / "interviews").mkdir(exist_ok=True)
    (run / "interviews" / f"{aid}.prompt.md").write_text(packet, encoding="utf-8")
    print(run / "interviews" / f"{aid}.prompt.md")


if __name__ == "__main__":
    main(sys.argv[1:])
