# Steps 3-5: config, run, interviews

## `config.json`

```json
{
  "platform": "broadcast",
  "start_hour": 9,
  "minutes_per_round": 60,
  "total_rounds": 8,
  "agents_per_hour": [2, 5],
  "peak_hours": [19, 20, 21, 22],
  "off_peak_hours": [0, 1, 2, 3, 4, 5],
  "opening_posts": [
    {"agent": "a01", "content": "…", "fact": "F1"}
  ],
  "injections": [
    {"round": 4, "kind": "news", "agent": "a07", "content": "…", "why": "tests a leaked memo"}
  ]
}
```

- `total_rounds x minutes_per_round` is the simulated horizon. Fast-moving events: 30-60 minute rounds, 1-3 days. Policy or product questions: 120 minutes or more, a few days to weeks. Round 1 starts at `start_hour`; the simulated hour of a round is `(start_hour + (round-1) * minutes_per_round / 60) mod 24`.
- `agents_per_hour`: minimum and maximum number of agents considered per simulated hour, at most 90% of the cast. The script scales it by the minutes per round and by the time-of-day multiplier (peak x1.5, off-peak x0.05, otherwise x1).
- `opening_posts` are posted at round 0 by the named agents, written by you from the seed facts (an official statement, the first news item). Each must cite a fact. At most one opening post per agent.
- `injections` are the "god's-eye" variables: an event, rumor, or statement that appears at the start of a given round, posted by a named agent. Use them to test a what-if. State why each exists. The original system generated such events but never applied them; here they are real.

## Platform styles

- `broadcast`: short posts, reposts, quotes, likes, follows. No threads. Visibility is driven by follows and engagement.
- `forum`: posts with threaded comments, likes and dislikes, and a "hot" ranking. Visibility is driven by engagement.

Actions allowed:

| | broadcast | forum |
|---|---|---|
| create | `post` | `post`, `comment` |
| amplify | `repost`, `quote` | none |
| react | `like` | `like`, `dislike` |
| social | `follow` | `follow`, `mute` |
| none | `nothing` | `nothing` |

## Log format

One JSON object per line in `rounds/NN.jsonl` (`NN` zero-padded, round 0 = opening posts):

```json
{"id":"r03#2","round":3,"sim_time":"Day 1 11:00","agent":"a02","name":"Dana Whitfield","action":"quote","target":"r00#1","content":"Cutting fees is fine, but who pays the transition cost?"}
```

`id` is `r<round>#<n>`, numbered in the order you append. `target` is the id of the post acted on, or null. `content` is empty for `like`, `follow`, `mute`, `nothing`. Never rewrite or delete log lines.

## Running a round

Round 0: `python3 scripts/append_turns.py <run> 0` writes the opening posts to `rounds/00.jsonl`.

For round R (1, 2, ...):

1. `python3 scripts/make_packets.py <run> R --seed 7` picks the active agents (same seed for the whole run, so it can be repeated), shows the round's scheduled injections in the feeds, and writes `turns/RR/<id>.prompt.md` for each active agent plus `turns/RR/active.json`. It prints the active ids.
2. Make one sub-agent call per active agent, all in one message so they run in parallel. Use `subagent_type: general-purpose`. A cheaper model is fine for `lite` runs of ordinary personas; use a strong model for institutions and key actors. The whole prompt of each call is: `Read <absolute run path>/turns/RR/<id>.prompt.md and follow it exactly.` (The agents need Read and Write.)
3. **Read the action from the file, never from the sub-agent's reply.** Each agent writes `turns/RR/<id>.json`. The reply text that comes back is often a summary of what the agent did and may omit the content, so do not parse it.
4. `python3 scripts/append_turns.py <run> R` validates the files and writes `rounds/RR.jsonl`: injections first, then the agents in id order, ids `r<RR>#<n>`. A missing or invalid turn is logged as `nothing` and printed as a WARNING with exit status 1: repeat that agent's call once (delete the log file first) or accept the `nothing`. The log is append-only otherwise.
5. Update `world_state.md` (below). Check the stop conditions.

What the scripts implement is described next so you can change a step by hand when needed.

### Turn packet (what `make_packets.py` writes)

Self-contained, so a sub-agent needs nothing else:

```
You are role-playing one participant in a rehearsal of a real situation. Stay in character. You are not an assistant here.

== WHO YOU ARE ==
<the full persona paragraph from cast/<id>.md>

== WHAT YOU KNOW ==
<only the facts this agent could know: ids and one-line statements>

== YOUR RECENT ACTIVITY ==
<this agent's last 5 actions, with their ids and content; "none yet" if empty>

== YOUR FEED (it is <sim_time>) ==
<up to 12 items, each with id, author name, content, and counts of likes/replies/reposts>

== YOUR TURN ==
Choose exactly one action: post | comment | repost | quote | like | dislike | follow | mute | nothing (only those allowed on this platform).
Act the way this person would at this moment. Doing nothing is a normal choice. Keep text natural and short (under 60 words unless the persona writes long). Do not invent dates, figures, names or quotes that are not in "What you know" or your feed; if you need one, stay vague.
Use the Write tool to create the file <ABSOLUTE PATH>/turns/RR/<id>.json containing exactly one JSON object and nothing else:
{"action":"...","target":"<id or null>","content":"<text or empty>"}
Then reply with the single word: done.
```

Create `turns/RR/` before launching the round. Do not tell the agent what the experiment hopes to show, other agents' personas, or anything from later rounds.

### Feed rules (implemented in `make_packets.py`)

From the log through round R-1 (and R's injections): posts by accounts the agent follows (newest first), then the most engaged recent posts (likes + 2 x replies + 2 x reposts, with the recent ones weighted up), then replies to the agent's own posts. Drop posts from muted accounts. Skip posts the agent already acted on. `log_view.py <run> stats` helps with the counts.

### `world_state.md`

Overwrite each round with at most 25 lines: the round and time; the dominant framings in circulation (with ids of the posts carrying them); who is arguing with whom; what has been conceded or denied; open questions the next rounds will answer. It is a digest for you to plan injections and for the report outline, not evidence: the report must cite the log.

### Stop conditions

Stop at `total_rounds`, or earlier when two consecutive rounds contain only `nothing` or likes. Stop and ask the user if more than 10% of calls produce invalid output (the persona or turn packet is probably unclear).

## Interviews (after the run)

For 3-6 agents with different stances, ask 3-4 open questions each (why did you do X? what would change your mind? what do you expect next? did you notice Y?). `python3 scripts/make_interview.py <run> <id> "<q1>" "<q2>"` writes `interviews/<id>.prompt.md` (persona, the agent's whole history with the posts it acted on, all posts, the questions). Call the sub-agent with "Read <abs path>/interviews/<id>.prompt.md and follow it exactly."; it writes `interviews/<id>.md`.

Treat answers as generated in-character reasoning, not recorded facts. They are evidence of what the persona would say, which is useful for mechanisms but not proof of anything real. They can contradict the log (in testing, an agent claimed to have published a story that another agent had published); check claims of fact against `log_view.py`.
