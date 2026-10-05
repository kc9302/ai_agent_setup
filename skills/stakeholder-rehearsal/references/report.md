# Step 6: report

The report is a set of scenario findings about the *simulated* world, written only from evidence in the run folder. Facts about the real world come from the seed and are tagged as such.

## Outline

Plan 2-5 sections before writing, from `world_state.md` and `log_view.py stats`. Each section is a finding, not a topic: "The official statement is reframed within two rounds" rather than "Reactions". Typical set: the core dynamic (what happened, in order); how groups behaved differently; where it could turn (risks and tipping points); what a variable changed (when branches exist). Write the outline into `outline.md` with one line per section saying what evidence would support it.

## Evidence gathering (per section)

Before writing a section, look things up in the run, at least three lookups of at least two different kinds:

- search: `log_view.py <run> search <keyword>`: find the posts that carry a framing;
- timeline: `log_view.py <run> timeline <agent>`, or `stats` for the round-by-round volume: show order and change;
- thread: `log_view.py <run> thread <id>`: read a whole exchange, with replies;
- interview: read or run an interview for the reasons behind an action.

Do not write a claim you have not looked up. If the log has no support for something the section would like to say, say that it was not observed.

## Writing rules

- Quote agents verbatim in their own paragraph, as a blockquote, ending with the speaker and a log id: 

  ```
  > Cutting fees is fine, but who pays the transition cost?
  > — Dana Whitfield [r03#2]
  ```
  Quotes may be shortened only with `…`, and the kept parts must be exact. Interview quotes use the id `iv:<agent>`.
- Tag each factual claim `[seed]` (from `facts.md`, give the fact id), `[simulated]` (observed in the log, give an id), or `[inferred]` (your interpretation; say what it rests on). Put the tag at the end of the sentence.
- Agents sometimes invent specifics (a year, a number, a name) and others then repeat them. Before using a detail from the log, check it against `facts.md`; if it is not there, say it arose in the run (`[simulated]`) and never present it as a seed fact. In testing, an invented year spread to three agents within two rounds.
- Never invent a username, quote, count, or interaction. Counts come from `log_view.py stats`.
- No headings inside a section; use bold for run-in labels. Do not repeat earlier sections.
- Write in the user's language. A quote in another language is translated, with the original kept in the log reference.
- Directly under the title, paste the notice from `references/report-notice.md` unchanged. `verify_quotes.py` requires it. Then give the question, the setup (size, rounds, seed, branches, and whether a baseline was run), and the assumed items from `facts.md`. Close with **Limits** (use the list in `SKILL.md`), and what to run next to firm up the finding (another seed, a variant, a different cast).
- Never write a probability. Describe mechanisms and conditions: "when X was posted before Y, the framing stuck".

## Baseline: what did the simulation add?

A report that sounds insightful may be what one model would have written without any simulation. Check with a control before claiming the run adds anything:

1. `python3 <skill>/scripts/make_baseline.py <run> <seed file>...` writes `baseline.prompt.md`.
2. One sub-agent call: "Read <abs path>/baseline.prompt.md and follow it exactly." It writes `baseline.md`.
3. In a short section of the report, **What the simulation added**, compare the two on the same questions: which findings appear only in the run (and which log entries show them), which appear in both (then the run confirmed rather than added), and which baseline claims the run contradicted. Quote the run, not the baseline.
4. If the run added nothing the baseline lacks, say so. That is a result.

One baseline and one run are two samples, not a test. Say that too.

## Verify before delivering

```
python3 <skill>/scripts/verify_quotes.py rehearsal/<slug>
```

It checks that the notice is present, that every blockquote appears in the log entry it cites, and that every cited id exists. Fix the report, not the log, until it passes. Mention in the final message that the quotes were verified (and that this does not verify the interpretation).

## Branches

For a what-if: copy the run folder to `<slug>-b/`, keep the cast, change only the injections (or one persona fact), reset `rounds/` and rerun with the same seed. In the report, compare the two runs on the same questions (who responded, which framing won, how fast it moved). Differences between runs with different seeds may be noise: say so unless both seeds were run for both branches.
