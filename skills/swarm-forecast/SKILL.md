---
name: swarm-forecast
description: Rehearse how a situation may unfold by simulating its stakeholders. Seed material (news, a policy draft, a launch plan, a crisis, a story) becomes a stakeholder map, a cast of personas, a round-by-round social simulation run by sub-agents, and an evidence-cited scenario report. Use when asked to "simulate the reaction", "predict how people will respond", "rehearse a PR crisis / policy / launch", "what-if with stakeholders", "swarm prediction", or in Korean "여론 시뮬레이션", "반응 예측", "이해관계자 시뮬레이션", "시나리오 리허설". Not a statistical forecast; read "Limits" before presenting results.
---

# swarm-forecast

Method: take real seed material, build a small world of stakeholders from it, let persona-driven agents act in rounds, then write a report that only cites what happened in the run. It reimplements the idea behind MiroFish (a swarm-intelligence prediction engine) as a Claude Code workflow. No server, no API key, no graph database. See `SOURCE.md`.

## When to use / not use

Use it to explore *plausible* reaction dynamics: who speaks first, which framing spreads, where a statement backfires, what a variable (an apology, a delay, a leak) changes.
Do not use it to produce probabilities, market forecasts, or anything presented as a measured prediction. Do not simulate private individuals; use public roles and fictional composites.

## Workflow

Work in a run folder `forecast/<slug>/` in the current project. Read the reference file for a step before doing it.

0. **Brief.** Write `brief.md`: the question to rehearse (one sentence), time horizon, platform style (`broadcast` = X-like short posts, `forum` = Reddit-like threads), size (`lite` = 6-10 agents x 6-12 rounds, default; `full` = 12-20 agents x 24+ rounds), and the seed files. Ask the user only if the question or the seed is missing.
1. **Facts and stakeholders** -> `facts.md`, `ontology.md`. Read `references/world-building.md`.
2. **Cast** -> `cast/<id>.md`, `cast.json`. Read `references/personas.md`.
3. **Config** -> `config.json` (rounds, round length, activity hours, opening posts, scheduled injections). Read `references/simulation.md`.
4. **Run** round by round with sub-agents. Read `references/simulation.md`. Log to `rounds/NN.jsonl`, keep `world_state.md` current.
5. **Interview** (optional) a few agents after the run.
6. **Report** -> `report.md`, then verify quotes. Read `references/report.md`.
7. **Branch** (optional): copy the run, change one variable via an injection, rerun, and compare in the report.

Scripts (Python 3, standard library only; `<skill>` is this skill's installed folder, for example `~/.claude/skills/swarm-forecast`, and `<run>` is `forecast/<slug>`):

```
python3 <skill>/scripts/make_packets.py <run> R --seed 7   # pick active agents, write their turn prompts
python3 <skill>/scripts/append_turns.py <run> R            # validate turn files, write rounds/RR.jsonl (R=0: opening posts)
python3 <skill>/scripts/log_view.py <run> stats|search <kw>|timeline <agent>|thread <id>
python3 <skill>/scripts/make_interview.py <run> <agent> "<question>" ...
python3 <skill>/scripts/verify_quotes.py <run>             # fails if a quote is not in the logs
python3 <skill>/scripts/pick_agents.py <run> R --seed 7    # just the activation draw (make_packets calls it)
```

A complete worked run (4 rounds, 6 agents, 2 interviews, a verified report) is in `examples/scooter/`. Read its `report.md` to see the target style.

## Rules that matter

- **Ground everything.** Every fact an agent relies on has an id in `facts.md` with a source quote. Mark anything you invented as `[assumed]`.
- **Stance lives in the persona text.** Concrete history, interests, triggers and a speaking style. A numeric "sentiment" value changes nothing; the persona sentence does.
- **Read actions from files.** Sub-agent replies are summaries and may omit the content; the scripts read `turns/RR/<id>.json`.
- **Agents are independent within a round.** Each agent turn gets only that agent's persona, its own recent actions, and a feed built from *earlier* rounds. Never let one sub-agent role-play several agents in the same turn.
- **The log is the only evidence.** The report may quote the log, interviews and seed facts, nothing else. Run `verify_quotes.py` before delivering.
- **Label the epistemic status** of every claim in the report: `[seed]`, `[simulated]`, `[inferred]`.
- **Cost guard.** State the planned number of sub-agent calls (active agents x rounds) before starting and get the user's go-ahead above 60 calls.

## Limits (say them in the report)

- Agents are one model playing roles. They share its priors, are more articulate and more consistent than real crowds, and under-represent silence, apathy and chaos.
- Small casts cannot show crowd effects. Outcomes vary between runs: for a decision that matters, run at least two seeds and report only what repeats.
- No calibration against real outcomes exists. Present results as scenarios with the mechanisms that produced them, not as likelihoods.
