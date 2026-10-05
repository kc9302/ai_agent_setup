#!/usr/bin/env python3
"""Build the single-call baseline prompt, the control for a simulation run.

usage: make_baseline.py <run_dir> <seed file> [<seed file> ...]

Writes <run_dir>/baseline.prompt.md: the same question and the same seed files,
but the model is asked to write the scenario report in ONE call with no
simulation. The sub-agent writes <run_dir>/baseline.md. Compare it with
report.md to see what the simulation added (see references/report.md). Give the
sub-agent only: "Read <abs path>/baseline.prompt.md and follow it exactly."
"""
import sys
from pathlib import Path


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    run = Path(argv[0]).resolve()
    seeds = [Path(a).resolve() for a in argv[1:]]
    brief = (run / "brief.md").read_text(encoding="utf-8").strip()
    out = run / "baseline.md"
    packet = f"""You are an analyst. Do not role-play and do not simulate a social network.

Read these seed files first:
{chr(10).join(f"- {p}" for p in seeds)}

Question to answer (from the brief):
{brief}

In one pass, write a scenario report of 400-700 words with 2-4 findings about how the stakeholders are likely to react and why. Quote only words that appear in the seed files, and tag each claim [seed] (stated in the seed files) or [inferred] (your reasoning). Do not invent dates, figures, names or quotes. Do not give probabilities.

Use the Write tool to create {out} with the report and nothing else. Then reply with the single word: done.
"""
    (run / "baseline.prompt.md").write_text(packet, encoding="utf-8")
    print(run / "baseline.prompt.md")


if __name__ == "__main__":
    main(sys.argv[1:])
