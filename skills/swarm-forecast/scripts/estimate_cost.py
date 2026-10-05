#!/usr/bin/env python3
"""Estimate how many sub-agent calls a run will need, before starting it.

usage: estimate_cost.py <run_dir> [--seed N] [--interviews K] [--baseline]

Reads config.json and cast.json and counts, for the given seed, how many agents
make_packets.py will activate in each round (one sub-agent call per active
agent), plus K interview calls and one baseline call if asked. Prints the total.
Above 60 calls, ask the user for a go-ahead before starting (see SKILL.md).

Tokens are not estimated here. In the one run this skill was tested on, each
turn call reported about 41-44k tokens on a small model (mostly fixed
overhead), so a 20-call run is on the order of a million tokens. Treat that as
one observation, not a guarantee; your model and persona length will differ.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from pick_agents import pick  # noqa: E402


def main(argv):
    argv = list(argv)
    seed, interviews, baseline = 0, 0, False
    if "--seed" in argv:
        i = argv.index("--seed")
        seed = int(argv[i + 1])
        del argv[i:i + 2]
    if "--interviews" in argv:
        i = argv.index("--interviews")
        interviews = int(argv[i + 1])
        del argv[i:i + 2]
    if "--baseline" in argv:
        baseline = True
        argv.remove("--baseline")
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 1:
        sys.exit(__doc__)
    run = Path(args[0])
    cfg = json.loads((run / "config.json").read_text(encoding="utf-8"))
    rounds = cfg["total_rounds"]
    per_round = [len(pick(run, r, seed)["active"]) for r in range(1, rounds + 1)]
    total = sum(per_round) + interviews + (1 if baseline else 0)
    print(f"rounds: {rounds}  calls per round: {per_round}")
    print(f"turn calls: {sum(per_round)}  interviews: {interviews}  baseline: {1 if baseline else 0}")
    print(f"TOTAL sub-agent calls: {total}")
    if total > 60:
        print("Above 60 calls: tell the user this number and wait for a go-ahead.")


if __name__ == "__main__":
    main(sys.argv[1:])
