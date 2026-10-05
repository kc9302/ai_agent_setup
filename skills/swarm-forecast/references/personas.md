# Step 2: cast

Create one file per agent, `cast/<id>.md` (ids `a01`, `a02`...), and one `cast.json` with the machine-readable part.

## Size

`lite`: 6-10 agents. `full`: 12-20. Pick agents so every ontology type that matters is present and at least two agents are expected to disagree. Include the actors that act first (they get the opening posts) and one or two low-activity, high-reach ones.

## `cast.json`

```json
[
  {"id": "a01", "name": "Ministry spokesperson", "type": "Regulator",
   "activity_level": 0.25, "active_hours": [9,10,11,12,13,14,15,16,17]},
  {"id": "a02", "name": "Dana Whitfield (shop owner)", "type": "RetailOwner",
   "activity_level": 0.8, "active_hours": [7,8,12,18,19,20,21,22]}
]
```

`activity_level` (0-1) is the chance an agent in its active hours acts in a given round. Active hours are in the simulated local time of that agent. Starting points: official bodies 0.1-0.3 and office hours, media 0.4-0.6 and most of the day, individuals 0.6-0.9 and evenings, experts 0.4-0.6. Adjust to the seed (a crisis makes everyone more active).

Only these fields drive the run. Do not add sentiment scores or influence weights; they would be ignored. Stance and reach come from the persona text and from who follows whom (below).

## `cast/<id>.md`: individuals

One coherent paragraph (about 150-300 words; longer is not better) covering:
- who they are: role, age band, where, what they do all day;
- their concrete connection to this situation and what they have already said or done (cite fact ids, for example "since F4");
- what they want and fear here, and what would make them angry, pleased, or silent (the triggers);
- how they use the platform: how often, what they post, whether they argue, reply, lurk, or pile on; their tone, language, habits;
- one or two quirks.

The file's **first line** is a header the scripts read, exactly in this form, followed by the persona text:

```
follows: a01, a05 | source facts: F1,F4
```

`follows` lists the agents whose posts this one sees first; `source facts` lists the fact ids it knows at the start.

Real named people: use only what the seed or their public role supports. Do not invent private details, and do not put invented quotes in a real person's mouth; for real figures prefer a role-based composite ("a regulator's spokesperson") unless the user insists.

## `cast/<id>.md`: institutions, media, groups

Same file, different content: formal identity and mandate; account positioning and audience; tone and what they never say; posting rhythm; how they handle criticism (ignore, correct, concede, escalate); who they answer to; their link to the situation and prior statements. Age, gender and personality types do not apply; do not invent them.

## Consistency check

Before the run: read the paragraphs side by side. Two agents that would behave identically are one agent; merge or differentiate. Check that each agent knows only facts it could know at the start (a rule published tomorrow is not known today).
