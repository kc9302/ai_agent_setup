#!/usr/bin/env python3
"""Write one round's log from opening posts, injections and agent turn files.

usage: append_turns.py <run_dir> <round>

Round 0: config.json "opening_posts" become the log.
Round R>=1: config.json "injections" for R come first, then turns/RR/<id>.json
for each agent in id order. Ids are assigned as r<round>#<n>. Output goes to
rounds/RR.jsonl (refuses to overwrite). Invalid or missing turns are logged as
"nothing" and reported on stderr, so the log never silently loses an agent.
A turn file is {"action": ..., "target": ..., "content": ...}.
Pass the ids of this round's active agents (from pick_agents.py) in
turns/RR/active.json as a JSON list so missing files can be detected.
"""
import json
import sys
from pathlib import Path

ACTIONS = {
    "broadcast": {"post", "repost", "quote", "like", "follow", "nothing"},
    "forum": {"post", "comment", "like", "dislike", "follow", "mute", "nothing"},
}
NEEDS_TEXT = {"post", "comment", "quote"}
NEEDS_TARGET = {"repost", "quote", "like", "dislike", "comment"}


def stamp(cfg, rnd):
    mins = cfg.get("start_hour", 9) * 60 + max(rnd - 1, 0) * cfg.get("minutes_per_round", 60)
    return f"Day {mins // 1440 + 1} {mins % 1440 // 60:02d}:{mins % 60:02d}"


def main(argv):
    if len(argv) != 2:
        sys.exit(__doc__)
    run, rnd = Path(argv[0]), int(argv[1])
    cfg = json.loads((run / "config.json").read_text(encoding="utf-8"))
    cast = {a["id"]: a for a in json.loads((run / "cast.json").read_text(encoding="utf-8"))}
    allowed = ACTIONS[cfg.get("platform", "broadcast")]
    out = run / "rounds" / f"{rnd:02d}.jsonl"
    if out.exists():
        sys.exit(f"{out} exists; the log is append-only, refusing to overwrite")
    known = set()
    for f in (run / "rounds").glob("*.jsonl"):
        known |= {json.loads(l)["id"] for l in f.read_text(encoding="utf-8").splitlines() if l.strip()}

    rows, n, warn = [], 0, []

    def add(agent, action, target, content):
        nonlocal n
        n += 1
        rows.append({"id": f"r{rnd:02d}#{n}", "round": rnd,
                     "sim_time": stamp(cfg, rnd), "agent": agent,
                     "name": cast[agent]["name"], "action": action,
                     "target": target, "content": content})

    if rnd == 0:
        for p in cfg.get("opening_posts", []):
            add(p["agent"], "post", None, p["content"])
    else:
        for p in [x for x in cfg.get("injections", []) if x["round"] == rnd]:
            add(p["agent"], "post", None, p["content"])
        tdir = run / "turns" / f"{rnd:02d}"
        active_f = tdir / "active.json"
        active = json.loads(active_f.read_text(encoding="utf-8")) if active_f.exists() else sorted(
            p.stem for p in tdir.glob("a*.json"))
        for aid in sorted(active):
            f = tdir / f"{aid}.json"
            try:
                t = json.loads(f.read_text(encoding="utf-8"))
                action, target, content = t["action"], t.get("target"), (t.get("content") or "").strip()
                if action not in allowed:
                    raise ValueError(f"action {action!r} not allowed on {cfg.get('platform')}")
                if action in NEEDS_TEXT and not content:
                    raise ValueError("empty content")
                if action in NEEDS_TARGET and target not in known:
                    raise ValueError(f"target {target!r} not an earlier post")
                if action == "follow" and target not in cast:
                    raise ValueError(f"follow target {target!r} not an agent id")
                if action == "post":
                    target = None
            except (OSError, ValueError, KeyError, json.JSONDecodeError) as e:
                warn.append(f"{aid}: {e}; logged as nothing")
                action, target, content = "nothing", None, ""
            add(aid, action, target, content)

    out.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8")
    print(f"{out}: {len(rows)} line(s)")
    for w in warn:
        print("WARNING " + w, file=sys.stderr)
    sys.exit(1 if warn else 0)


if __name__ == "__main__":
    main(sys.argv[1:])
