---
name: end-meeting
description: Read the answers written by hand into a meeting agenda, compile them into an action list, ask any clarifying questions in one round, then execute — amending the working docs, applying code and documentation changes, and filing tracker issues, routing each through the review path its own file requires. Use once every item in the agenda has a written response.
---

# End meeting

Read the answers people wrote into a prepared agenda, compile them into an action list, and make the
changes. **This is the only one of the three that touches real files**, and it runs after the
meeting, usually in a fresh session. The `Response` blocks are the contract: everything they call
for gets done, nothing they do not does. **It compiles the action list itself** rather than reading
one transcribed mid-meeting, because that list then gets shown and confirmed, which is where a
misreading gets caught.

## 0. Set up, and refuse the unsafe cases

```bash
eval "$(.claude/bin/task.sh paths)"      # TRACKER_CLI, TRACKER_REPO, KIND_LABELS, LABELS_DERIVED, ...
git -C .claude pull --ff-only
```

`/end-meeting [YYYY-MM-DD]`, defaulting to the most recent agenda. **Stop, with a plain report, if
any of these holds:**

- **`Status: executed`.** It has already run. Report what it did and stop: a second run duplicates
  decision entries and re-files issues.
- **Any `Response` block is empty**, placeholder or blank. **Stop and ask, every time, whatever the
  item's status.** List the empty ones and wait for a ruling on each: an empty block is ambiguous
  between *not discussed*, *nothing to do*, and *I thought I wrote that*, and a `Close` nobody
  answered looks exactly like a `Close` everyone agreed to. **Never infer it from the status.**
- **Every block is empty.** Nothing was written. Say so and stop.
- **The working tree is dirty in anything this run will edit.** Report what is dirty and stop.

## 1. Compile the action list, ask, then confirm

Read the whole file, the `## Other Notes` section included: what is written there is real
instruction, compiled into the list like any `Response` block, and an empty one needs no question.
The `Response` is the decision; the brief and question are the context that makes it legible. Produce
**one list of concrete actions**, each naming the file it touches and the route it takes. Group every
clarifying question into **one round**, then show the list and **get one confirmation before doing
anything.** An action the `Response` blocks do not call for stays off the list, however good it
looks; if you think something is missing, ask it in that same round.

## 2. Execute, routing each change correctly

**Read the project's own `CLAUDE.md` for the routing table and follow it**: it differs per project.
The shape it generally takes:

| Change | Typical route |
|---|---|
| Working docs, the decision log, collab, traps | direct to the default branch |
| Anything executable: hooks, settings, skill frontmatter | branch and review, always |
| Source, and any authority document | branch and review |
| Tracker issues | filed one at a time, each confirmed, each verified after filing |

Two rules hold regardless of the routing table: **everyone in the meeting decided this, so co-author
the commits to the people present**; and **never merge the review branch**, open it and stop, since
the point of review is that someone who was not writing reads it.

## 3. Sweep the items, each according to its `Response`

- **Decided** → make the change, append a dated entry to `decisions.md` saying what and why, mark
  the `collab.md` item settled. **Ratified** → the same, noting it confirms what was already built.
- **Acknowledged** → mark it acknowledged in `collab.md`; no other change. **Closed** → mark it
  settled with the reason. **FYI** → nothing.
- **Parked** → leave it open in `collab.md` with a note on what it waits for, or file it as a
  tracker issue when it has a shape but no date.

Then move every settled item into `collab_settled.md` and run the audits its preamble prescribes,
the duplicate-line and structural checks, **before** committing. Moving items is the one operation
that can splice two entries together, and neither git nor union merge will tell you. Process
`work/pipeline_backlog.md` in the same pass: apply what was agreed, remove each applied entry, and
record its disposition in the entry you are already writing.

## 4. The tracker

**When `TRACKER_CLI` is `none`, skip this section entirely**, with one line in the report: tracker
steps skipped, the decisions stay in the working docs. Otherwise file **one issue at a time**,
printing the exact title, body and target repo and waiting for an OK each time. Never batch the
confirmations. The generic shape, then the two CLIs:

    <TRACKER_CLI> issue create --title <t> --body-file <f> --label <kind> --milestone <m>

```bash
gh   issue create --repo "$TRACKER_REPO" --title "..." --body-file body.md --label task --milestone "Backlog"
glab issue create --repo "$TRACKER_REPO" --title "..." --description-file body.md --label task --milestone "Backlog"
```

- **Exactly one kind label**, from `KIND_LABELS`. When `KIND_LABELS` is empty, pass no labels at all:
  a label name that does not exist is created on use, silently, so never invent one.
- **Never pass a derived label** when `LABELS_DERIVED=yes`. The tracker derives those itself from the
  title and body, and a hand-passed one competes with what the project already decided.
- **Every issue carries a milestone**, which is where the sequencing lives.
- **Verify after filing**, because the exit code is not evidence the body survived. Read it back with
  `gh issue view <n> --json title,body` or `glab issue view <n>`, and check the fences and tables.
- **Closing a `NEEDS_RULING_LABEL` issue owes three things**, not just the close: the ruling appended
  to `decisions.md` **with the option not taken**; every document the ruling binds amended, each
  routed by the project's review-routing table; and the implementation issue filed and linked to the
  closed one, so the close is not the only record.

## 5. Stamp and report

Set the header to `Status: executed` with the date and one line naming where the docs landed and
which review branch carries the rest. Then report: what changed, what was filed and verified, what
waits on review, and anything you asked that nobody answered.

## Constraints

- **The `Response` blocks and `Other Notes` are the contract.** Not the brief, not your own view.
- **One confirmation before executing, then execute the whole list.** Do not stop halfway to ask
  what you could have asked in the first round: a half-applied meeting is indistinguishable from a
  finished one to the next session.
- **Never merge. Never approve. Never edit anyone's `Response`**; if one is ambiguous, ask.
