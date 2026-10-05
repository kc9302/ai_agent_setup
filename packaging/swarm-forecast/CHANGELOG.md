# Changelog

## 0.1.0

- First public version: facts, ontology, personas, round-by-round sub-agent run, interviews, evidence-cited report.
- Scripts: `make_packets`, `append_turns`, `pick_agents`, `log_view`, `make_interview`, `verify_quotes`.
- `verify_quotes.py` checks that each quote is inside the log entry it cites.
- Fixed before release: `--seed N` swallowed a round argument equal to N (found by the test suite).
