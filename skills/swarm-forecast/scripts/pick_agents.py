#!/usr/bin/env python3
"""Pick the agents that act in one simulation round.

usage: pick_agents.py <run_dir> <round> [--seed N]

Reads <run_dir>/config.json and <run_dir>/cast.json and prints JSON:
{"round": R, "sim_hour": H, "target": T, "active": ["a02", ...]}

Rule: target = uniform(min, max) of agents_per_hour, scaled by the share of an
hour one round covers and by the time-of-day multiplier (peak 1.5, off-peak
0.05, else 1). Candidates are agents whose active_hours contain the hour; each
passes with probability activity_level; a random sample of up to `target` of
them acts. The draw depends only on (seed, round), so a run can be repeated.
"""
import json
import math
import random
import sys
from pathlib import Path

PEAK, OFF_PEAK = 1.5, 0.05


def pick(run, rnd, seed=0):
    cfg = json.loads((run / "config.json").read_text(encoding="utf-8"))
    cast = json.loads((run / "cast.json").read_text(encoding="utf-8"))
    minutes = cfg.get("minutes_per_round", 60)
    hour = int((cfg.get("start_hour", 9) + (rnd - 1) * minutes / 60) % 24)
    lo, hi = cfg.get("agents_per_hour", [1, max(1, len(cast) // 2)])
    cap = max(1, int(0.9 * len(cast)))
    lo, hi = min(lo, cap), min(max(hi, lo), cap)

    rng = random.Random(f"{seed}:{rnd}")
    mult = PEAK if hour in cfg.get("peak_hours", []) else OFF_PEAK if hour in cfg.get("off_peak_hours", []) else 1.0
    target = rng.uniform(lo, hi) * mult * (minutes / 60)
    target = max(1, int(round(target))) if mult > OFF_PEAK else int(round(target))
    target = min(target, cap)  # an agent acts at most once per round

    cands = [a["id"] for a in cast
             if hour in a.get("active_hours", range(8, 23))
             and rng.random() < a.get("activity_level", 0.5)]
    rng.shuffle(cands)
    return {"round": rnd, "sim_hour": hour, "target": target, "active": sorted(cands[:target])}


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    seed = 0
    if "--seed" in argv:
        i = argv.index("--seed")
        seed = int(argv[i + 1])
        args = [a for a in args if a != argv[i + 1]]
    if len(args) != 2:
        sys.exit(__doc__)
    print(json.dumps(pick(Path(args[0]), int(args[1]), seed)))


if __name__ == "__main__":
    main(sys.argv[1:])
