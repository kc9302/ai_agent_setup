# Origin

An independent reimplementation of the *workflow idea* behind **MiroFish** (https://github.com/666ghj/MiroFish, AGPL-3.0), studied at commit `7657031ac01184afe2cb220f5ee3545573b5e843`.

MiroFish is a Flask + Vue application that needs an LLM key and a Zep Cloud key. It builds a knowledge graph from seed documents, generates agent personas, runs a Twitter/Reddit-style simulation on the OASIS library, and writes a report with a tool-using agent. This skill keeps the stages and replaces the infrastructure with files and sub-agents.

**No MiroFish code or prompt text is copied.** The scripts and all instructions here were written for this repository. Ideas and numeric defaults (for example the 10-type ontology with two fallback types, a peak-hour multiplier) are method descriptions, not expression. If you later copy anything from MiroFish into this skill, the AGPL-3.0 terms apply to that part and this file must say so.

## What was kept, changed, added

| Stage | MiroFish | Here |
|---|---|---|
| Seed -> world | Ontology by LLM, entities extracted by Zep into a graph | `facts.md` (sourced facts) + `ontology.md` (actor types), by the main agent |
| Personas | LLM per entity, individual vs institution templates | Same split; stance written into the persona text |
| Config | LLM-generated time, activity, opening posts | Same fields, but only those the run loop actually uses (the original generates several it never reads) |
| Run | OASIS, 2 platforms in parallel, activation by hour x activity level | `pick_agents.py` reproduces the activation rule; one sub-agent call per active agent |
| Event injection | Opening posts only; scheduled events are generated but unused | Scheduled injections are really applied (added) |
| Memory | Activity written back to Zep | `world_state.md` digest + the round logs |
| Report | ReACT agent, 3-5 tool calls per section, citation by prompt | Evidence lookups with `log_view.py`; quotes **verified by script** (added) |
| Interviews | IPC to the live OASIS process | Persona + the agent's own history re-instantiated |
| Variants | none | Branch-and-compare (added) |

Observed weaknesses of the original that this skill designs around: unmatched entities silently dropped; most generated parameters unused; anti-fabrication enforced only by prompt; no resume; no mid-run injection.
