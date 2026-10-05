#!/usr/bin/env python3
"""Build the turn packets for one round.

usage: make_packets.py <run_dir> <round> [--seed N]

Chooses the active agents (same rule as pick_agents.py), then writes
turns/RR/active.json and one turns/RR/<id>.prompt.md per active agent: persona,
the facts it knows, its last actions, its feed, and instructions to write its
action to turns/RR/<id>.json. Give each sub-agent only this instruction:
"Read <abs path>/turns/RR/<id>.prompt.md and follow it exactly."

Persona files (cast/<id>.md) start with a header line
"follows: a01, a05 | source facts: F1,F3" followed by the persona text.
Injections scheduled for this round are shown in the feed with the ids
append_turns.py will give them (r<RR>#1, #2, ... in config order).
"""
import json
import re
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from append_turns import ACTIONS, stamp  # noqa: E402
from pick_agents import pick  # noqa: E402

FEED_MAX, RECENT_MAX = 12, 5


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    seed = 0
    if "--seed" in argv:
        i = argv.index("--seed")
        seed = int(argv[i + 1])
        args = [a for a in args if a != argv[i + 1]]
    if len(args) != 2:
        sys.exit(__doc__)
    run, rnd = Path(args[0]).resolve(), int(args[1])
    cfg = json.loads((run / "config.json").read_text(encoding="utf-8"))
    cast = {a["id"]: a for a in json.loads((run / "cast.json").read_text(encoding="utf-8"))}
    facts = {}
    for line in (run / "facts.md").read_text(encoding="utf-8").splitlines():
        m = re.match(r"^(F\d+)\s*\|\s*([^|]+)", line)
        if m:
            facts[m.group(1)] = m.group(2).strip()

    rows = []
    for f in sorted((run / "rounds").glob("*.jsonl")):
        rows += [json.loads(l) for l in f.read_text(encoding="utf-8").splitlines() if l.strip()]
    for k, inj in enumerate([x for x in cfg.get("injections", []) if x["round"] == rnd], 1):
        rows.append({"id": f"r{rnd:02d}#{k}", "round": rnd, "agent": inj["agent"], "name": cast[inj["agent"]]["name"],
                     "action": "post", "target": None, "content": inj["content"], "sim_time": stamp(cfg, rnd)})

    posts = [r for r in rows if r["action"] in ("post", "quote", "comment") and r.get("content")]
    eng = {p["id"]: Counter() for p in posts}
    for r in rows:
        if r.get("target") in eng and r["action"] in ("like", "dislike", "repost", "quote", "comment"):
            eng[r["target"]][r["action"]] += 1
    score = lambda pid: eng[pid]["like"] + 2 * (eng[pid]["comment"] + eng[pid]["quote"] + eng[pid]["repost"])

    chosen = pick(run, rnd, seed)
    tdir = run / "turns" / f"{rnd:02d}"
    tdir.mkdir(parents=True, exist_ok=True)
    (tdir / "active.json").write_text(json.dumps(chosen["active"]), encoding="utf-8")
    actions = ", ".join(sorted(ACTIONS[cfg.get("platform", "broadcast")] - {"nothing"})) + ", nothing"
    now = stamp(cfg, rnd)

    for aid in chosen["active"]:
        text = (run / "cast" / f"{aid}.md").read_text(encoding="utf-8").strip().splitlines()
        header = text[0] if text and text[0].startswith("follows:") else ""
        persona = "\n".join(text[1:] if header else text).strip()
        follows = set(re.findall(r"a\d+", header.split("|")[0]))
        known = re.findall(r"F\d+", header.split("source facts:")[1]) if "source facts:" in header else []
        mine = [r for r in rows if r["agent"] == aid]
        acted_on = {r["target"] for r in mine if r.get("target")}

        own = {p["id"] for p in posts if p["agent"] == aid}
        cands = [p for p in reversed(posts) if p["agent"] != aid and p["id"] not in acted_on]
        feed = [p for p in cands if p["agent"] in follows]
        feed += sorted((p for p in cands if p not in feed), key=lambda p: -score(p["id"]))
        replies = [p for p in cands if p.get("target") in own and p not in feed]
        feed = (replies + feed)[:FEED_MAX]

        def fmt(p):
            e = eng[p["id"]]
            return (f'[{p["id"]}] {p["name"]}: "{p["content"]}" '
                    f'(likes {e["like"]}, reposts {e["repost"]}, quotes {e["quote"] + e["comment"]})')

        recent = [f'{r["sim_time"]} {r["action"]}'
                  + (f' on [{r["target"]}]' if r.get("target") else "")
                  + (f' [{r["id"]}]: "{r["content"]}"' if r.get("content") else f' [{r["id"]}]')
                  for r in mine[-RECENT_MAX:]]
        out = tdir / f"{aid}.json"
        packet = f"""You are role-playing one participant in a rehearsal of a real situation. Stay in character. You are not an assistant here.

== WHO YOU ARE ==
{persona}

== WHAT YOU KNOW ==
{chr(10).join(f"{f}: {facts[f]}" for f in known if f in facts) or "Only what is in your feed."}

== YOUR RECENT ACTIVITY ==
{chr(10).join(recent) or "none yet"}

== YOUR FEED (it is {now}; short posts) ==
{chr(10).join(fmt(p) for p in feed) or "(empty)"}

== YOUR TURN ==
Choose exactly one action: {actions}.
Act the way this participant would at this moment. Doing nothing is a normal choice. Keep text natural and short (under 60 words unless the persona writes long). Do not invent dates, figures, names or quotes that are not in "What you know" or your feed; if you need one, stay vague. For like/repost/quote/comment, "target" is the id of the post in your feed.
Use the Write tool to create the file {out} containing exactly one JSON object and nothing else:
{{"action":"...","target":"<id or null>","content":"<text or empty>"}}
Then reply with the single word: done.
"""
        (tdir / f"{aid}.prompt.md").write_text(packet, encoding="utf-8")
    print(json.dumps(chosen))


if __name__ == "__main__":
    main(sys.argv[1:])
