#!/usr/bin/env python3
"""Build scenes.json for the demo GIF from the REAL example run.

Every command output shown in the GIF is produced by running the actual scripts
on skills/stakeholder-rehearsal/examples/scooter (a tampered copy is used for
the failing check). Run: python3 build_scenes.py <repo_root> <out.json>
"""
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root, out = Path(sys.argv[1]).resolve(), Path(sys.argv[2])
skill = root / "skills" / "stakeholder-rehearsal"
tmp = Path(tempfile.mkdtemp())
(tmp / "rehearsal").mkdir()
shutil.copytree(skill / "examples" / "scooter", tmp / "rehearsal" / "scooter")
(tmp / "scripts").symlink_to(skill / "scripts")
run_dir = tmp / "rehearsal" / "scooter"


def sh(cmd):
    p = subprocess.run(cmd, shell=True, cwd=tmp, capture_output=True, text=True)
    return [l for l in (p.stdout + p.stderr).splitlines()], p.returncode


def clip(s, n):
    return s if len(s) <= n else s[: n - 1] + "…"


def jl(p):
    return [json.loads(l) for l in p.read_text(encoding="utf-8").splitlines() if l.strip()]


facts = [l for l in (run_dir / "facts.md").read_text(encoding="utf-8").splitlines() if l.startswith("F")][:4]
cast = json.loads((run_dir / "cast.json").read_text(encoding="utf-8"))
rows = {r["id"]: r for n in range(5) for r in jl(run_dir / "rounds" / f"{n:02d}.jsonl")}
show_ids = ["r00#1", "r01#1", "r01#4", "r02#5", "r03#1", "r03#6"]


def post(i):
    r = rows[i]
    return f'[{i}] {r["name"]} · {r["action"]}: {clip(r["content"], 120)}'


cost, _ = sh("python3 scripts/estimate_cost.py rehearsal/scooter --seed 7 --interviews 2 --baseline")
stats, _ = sh("python3 scripts/log_view.py rehearsal/scooter stats")
thread, _ = sh('python3 scripts/log_view.py rehearsal/scooter thread "r03#1"')
report = (run_dir / "report.md").read_text(encoding="utf-8").splitlines()
notice = next(l for l in report if l.startswith("**Notice.**"))
finding = next(i for i, l in enumerate(report) if l.startswith("> so 40km"))
ok, _ = sh("python3 scripts/verify_quotes.py rehearsal/scooter")

# tamper with one quote in a copy and run the real check
tampered = run_dir / "report_tampered.md"
txt = (run_dir / "report.md").read_text(encoding="utf-8").replace(
    "so 40km in 2 years but lanes are zero today? where do i ride tomorrow?",
    "so 40km in 2 years but lanes are zero today? where do i ride tomorrow? the city will fix it by march.", 1)
tampered.write_text(txt, encoding="utf-8")
bad, rc = sh("python3 scripts/verify_quotes.py rehearsal/scooter rehearsal/scooter/report_tampered.md")
assert rc == 1 and any("NOT IN CITED ID" in l for l in bad), bad
assert any("0 problem" in l for l in ok), ok

W = 108
scenes = [
    {"title": "1 / 6  Seed files become a sourced fact table", "lines": [
        ("dim", "# a fictional seed: seed.md (a city bans delivery e-scooters from sidewalks)"),
        ("cmd", "$ cat rehearsal/scooter/facts.md"),
        *[("out", clip(f, W * 2)) for f in facts],
        ("dim", "# every fact has an id and a quoted source; invented ones are tagged [assumed]")]},
    {"title": "2 / 6  A cast, and the cost before you start", "lines": [
        ("cmd", "$ cat rehearsal/scooter/cast.json   # 6 agents, one persona file each"),
        *[("out", f'{a["id"]}  {a["name"]:<24} {a["type"]:<20} activity {a["activity_level"]}') for a in cast],
        ("cmd", "$ python3 scripts/estimate_cost.py rehearsal/scooter --seed 7 --interviews 2 --baseline"),
        *[("out", l) for l in cost]]},
    {"title": "3 / 6  Rounds: one independent sub-agent call per active agent", "lines": [
        ("cmd", "$ cat rehearsal/scooter/rounds/*.jsonl   # append-only log, excerpt"),
        *[("inj" if i == "r03#1" else "out", post(i)) for i in show_ids],
        ("dim", "# r03#1 is a scheduled injection: a news item posted at round 3"),
        ("cmd", "$ python3 scripts/log_view.py rehearsal/scooter stats"),
        *[("out", l) for l in stats[:6]]]},
    {"title": "4 / 6  What happened to the injected story?", "lines": [
        ("cmd", '$ python3 scripts/log_view.py rehearsal/scooter thread "r03#1"'),
        *[("inj", clip(l, W * 2)) for l in thread],
        ("dim", "# no reply, quote, like or repost: the funding story did not spread"),
        ("dim", "# the frame that did: \"fines start on 1 June, but the lanes do not exist yet\"")]},
    {"title": "5 / 6  The report opens with a notice and cites the log", "lines": [
        ("cmd", "$ sed -n '3p;%d,%dp' rehearsal/scooter/report.md" % (finding + 1, finding + 2)),
        ("notice", clip(notice, W * 3)),
        ("out", report[finding]),
        ("out", report[finding + 1])]},
    {"title": "6 / 6  Quotes are machine-checked against the log", "lines": [
        ("cmd", "$ python3 scripts/verify_quotes.py rehearsal/scooter/report_tampered.md   # one quote altered"),
        *[("bad", clip(l, W * 2)) for l in bad],
        ("cmd", "$ python3 scripts/verify_quotes.py rehearsal/scooter"),
        *[("good", l) for l in ok]]},
    {"title": "stakeholder-rehearsal", "final": True, "lines": [
        ("big", "Rehearse how a situation may unfold."),
        ("big", "Scenarios and their mechanisms, not forecasts."),
        ("out", "One model plays everyone. Quotes are checked against the log. Not calibrated."),
        ("cmd", "$ npx skills add <owner>/stakeholder-rehearsal --skill stakeholder-rehearsal")]},
]
out.write_text(json.dumps(scenes, ensure_ascii=False, indent=1), encoding="utf-8")
shutil.rmtree(tmp)
print(f"{len(scenes)} scenes, {sum(len(s['lines']) for s in scenes)} lines")
