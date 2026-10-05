#!/usr/bin/env python3
"""Read a simulation run's logs.

usage: log_view.py <run_dir> stats
       log_view.py <run_dir> search <keyword>
       log_view.py <run_dir> timeline <agent id or name part>
       log_view.py <run_dir> thread <post id>

Logs are <run_dir>/rounds/NN.jsonl, one JSON action per line.
"""
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path


def load(run):
    rows = []
    for f in sorted((run / "rounds").glob("*.jsonl")):
        for n, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            if line.strip():
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    print(f"warning: {f.name}:{n} is not valid JSON", file=sys.stderr)
    return rows


def show(r):
    tgt = f" -> {r['target']}" if r.get("target") else ""
    txt = f": {r['content']}" if r.get("content") else ""
    return f"[{r['id']}] {r.get('sim_time', '')} {r.get('name', r['agent'])} {r['action']}{tgt}{txt}"


def engagement(rows):
    e = defaultdict(lambda: Counter())
    for r in rows:
        t = r.get("target")
        if t and r["action"] in ("like", "dislike", "repost", "quote", "comment"):
            e[t][r["action"]] += 1
    return e


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    run, cmd, rest = Path(argv[0]), argv[1], argv[2:]
    rows = load(run)
    if cmd == "stats":
        by_round = defaultdict(Counter)
        for r in rows:
            by_round[r["round"]][r["action"]] += 1
        print("round | " + " ".join(f"{k}={v}" for k, v in sorted(Counter(r["action"] for r in rows).items())))
        for rd in sorted(by_round):
            print(f"{rd:>5} | " + " ".join(f"{k}={v}" for k, v in sorted(by_round[rd].items())))
        eng = engagement(rows)
        posts = {r["id"]: r for r in rows if r["action"] in ("post", "comment", "quote")}
        top = sorted(eng, key=lambda i: -(eng[i]["like"] + 2 * eng[i]["comment"] + 2 * eng[i]["repost"] + 2 * eng[i]["quote"]))[:5]
        print("most engaged:")
        for i in top:
            if i in posts:
                print("  " + show(posts[i]) + "  " + " ".join(f"{k}={v}" for k, v in eng[i].items()))
    elif cmd == "search" and rest:
        kw = " ".join(rest).lower()
        hits = [r for r in rows if kw in (r.get("content") or "").lower()]
        print("\n".join(show(r) for r in hits) or "no matches")
    elif cmd == "timeline" and rest:
        q = " ".join(rest).lower()
        hits = [r for r in rows if q == r["agent"].lower() or q in r.get("name", "").lower()]
        print("\n".join(show(r) for r in hits) or "no matches")
    elif cmd == "thread" and rest:
        root = rest[0]
        ids = {root}
        grew = True
        while grew:
            grew = False
            for r in rows:
                if r.get("target") in ids and r["id"] not in ids:
                    ids.add(r["id"])
                    grew = True
        print("\n".join(show(r) for r in rows if r["id"] in ids) or "no such id")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
