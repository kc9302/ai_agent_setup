# Step 1: facts and stakeholders

Goal: turn the seed material into (a) a numbered list of sourced facts and (b) a set of actor types. This replaces the knowledge graph of the original system.

## 1a. `facts.md`

Read every seed file fully (or the relevant parts of long ones; say which parts you sampled). Write one fact per line:

```
F1 | The ministry announced the fee cut on 3 March. | "…announced on 3 March that fees will be cut by…" (policy.pdf p.2)
F2 | [assumed] Local retailers learn of it from trade media first. | no source; plausible
```

Rules:
- A fact is something stated or clearly implied by the seed. Quote the supporting words and name the file and page or heading.
- Anything you add from general knowledge or imagination is tagged `[assumed]`. Keep these few; list them for the user at the end.
- Capture relationships as facts too ("A regulates B", "C is employed by D", "E publicly opposed F before"). They decide who reacts to whom.
- Include timing facts (dates, deadlines, who acts first). They decide the opening posts.

## 1b. `ontology.md`

Define actor types. An actor is anyone who could post, comment, or act in public about this situation.

Valid: named individuals, companies (incl. their official voice), organizations, government bodies and regulators, media outlets, platforms themselves, and representative voices of groups (a fan community, an alumni association).
Invalid: abstractions ("public opinion", "the market"), topics, and stances ("supporters"). A stance belongs inside a persona, not as an actor.

Rules:
- At most 10 types. The last two are always the fallbacks `Person` and `Organization`; the first eight are specific to this seed (for example `Regulator`, `ConsumerAdvocate`, `Journalist`, `RetailOwner`).
- Each specific type gets a one-line boundary that says how it differs from its fallback.
- List 6-10 relationship kinds that matter here (REGULATES, EMPLOYS, CRITICIZES, REPORTS_ON...).
- **Coverage check (do not skip).** For each type write the facts that justify it. Then ask: who is missing? A silent role (for example the affected group with no spokesperson) is the usual hole. If a needed role has no source, add it as `[assumed]` and say so.
- If the seed is long and you sampled it, say so, and expect roles that only appear in unsampled parts to be missing.

Stop here and show the user the type list and the assumed items when the cast will be `full` size. For `lite` just proceed.
