# Changelog

## 0.2.1

- Renamed from `swarm-forecast` to `stakeholder-rehearsal`: the tool rehearses reactions, it does not forecast. The run folder is now `rehearsal/<slug>/`.
- Demo GIF in the README, generated from the bundled example by `docs/demo/` (all command output in it is real script output).

## 0.2.0

- Every report must open with the standard notice (`references/report-notice.md`); `verify_quotes.py` fails without it (`--no-notice` to skip).
- `estimate_cost.py`: counts sub-agent calls for a seed before the run, warns above 60.
- `make_baseline.py` and a "What the simulation added" section in the report rules: a single-call control on the same seed. The example report now includes one.
- Tests: 34.

## 0.1.0

- First public version: facts, ontology, personas, round-by-round sub-agent run, interviews, evidence-cited report.
- Scripts: `make_packets`, `append_turns`, `pick_agents`, `log_view`, `make_interview`, `verify_quotes`.
- `verify_quotes.py` checks that each quote is inside the log entry it cites.
- Fixed before release: `--seed N` swallowed a round argument equal to N (found by the test suite).
