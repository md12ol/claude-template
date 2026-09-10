---
name: end-meeting
description: Read the answers written by hand into a meeting agenda, compile them into an action list, ask any clarifying questions in one round, then execute — amending the working docs, applying code and documentation changes, and filing tracker issues, routing each through the review path its own file requires. Use once every item in the agenda has a written response.
---

# End meeting

Read the answers people wrote into a prepared agenda, compile them into an action list, and actually
make the changes. **This is the only one of the three that touches real files.**

**It runs after the meeting, not during it, and usually in a fresh session.** The `Response` blocks
are the contract: everything they call for gets done, nothing they do not does.

**It compiles the action list itself** rather than reading one transcribed during the meeting — a
list written mid-thought is less clear than one written from the finished answers, and compiling it
here means it gets shown and confirmed, which is where a misreading gets caught.

## 0. Set up, and refuse the unsafe cases

```bash
git -C .claude pull --ff-only
```

`/end-meeting [YYYY-MM-DD]`, defaulting to the most recent agenda. **Stop, with a plain report, if
any of these holds:**

- **`Status: executed`.** It has already run. Report what it did and stop — a second run duplicates
  decision entries and re-files issues.
- **Any `Response` block is empty**, still carrying its placeholder or nothing at all. **Stop and
  ask, every time, whatever the item's status is.** List the empty ones and wait for a ruling on
  each. An empty block is genuinely ambiguous between *not discussed*, *nothing to do*, and *I
  thought I wrote that* — and the third is the expensive one, because a `Close` item nobody answered
  is indistinguishable from a `Close` item everyone agreed to. **Never infer from the status which
  of the three it is.**
- **Every block is empty.** Nothing was written. Say so and stop.
- **The working tree is dirty in anything this run will edit.** Report what is dirty and stop.

## 1. Compile the action list, ask, then confirm

Read the whole file — every brief, question and `Response`. The `Response` is the decision; the
brief and question are the context that makes it legible.

Then produce **one list of concrete actions**, each naming the file it touches and the route it
takes. Group the clarifying questions into **one round** — not one at a time, and not per item.
Then show the list and **get one confirmation before doing anything.**

An action the `Response` blocks do not call for does not go on the list, however obviously good it
looks. If you think something is missing, say so as a question in the same round.

## 2. Execute, routing each change correctly

**Read the project's own `CLAUDE.md` for the routing table and follow it.** It differs per project
and this skill must not assume one. The shape it generally takes:

| Change | Typical route |
|---|---|
| Working docs — decisions, collab, traps, issues, deferred | direct to the default branch |
| Anything executable — hooks, settings, skill frontmatter | branch and review, always |
| Source, and any authority document | branch and review |
| Tracker issues | filed one at a time, each confirmed, each verified after filing |

Two rules that hold regardless of the routing table:

- **Everyone in the meeting decided this, so the commits say so.** Co-author them to the people
  present.
- **Never merge the review branch.** Open it and stop. The point of review is that someone who was
  not writing reads it.

## 3. Sweep the items

For each item, according to its `Response`:

- **Decided** → make the change, append a dated entry to `decisions.md` saying what and why, mark
  the `collab.md` item settled.
- **Ratified** → same, noting it confirms what was already built.
- **Acknowledged** → mark it acknowledged in `collab.md`; no other change.
- **Parked** → leave it open in `collab.md` with a note on what it waits for; consider
  `work/deferred.md` if it has a shape but no date.
- **Closed** → mark it settled with the reason.
- **FYI** → nothing.

Then move every item now settled into `collab_settled.md`, and run the audits its preamble
prescribes — the duplicate-line check and the structural check — **before** committing. Moving items
is the one operation that can splice two entries together, and neither git nor union merge will tell
you.

Process `work/pipeline_backlog.md` in the same pass: apply what was agreed, remove each applied
entry, and record its disposition in the same entry you are already writing.

## 4. Stamp and report

Set the header to `Status: executed` with the date, and add one line naming where the docs landed
and which review branch carries the rest. Then report: what changed, what was filed, what is
waiting on review, and anything you asked about that nobody answered.

## Constraints

- **The `Response` blocks are the contract.** Not the brief, not the question, not what you would
  have decided.
- **One confirmation before executing, then execute the whole list.** Do not stop halfway to ask
  something you could have asked in the first round — a half-applied meeting is indistinguishable
  from a finished one to the next session.
- **Never merge.** Never approve.
- **Never edit anyone's `Response`.** If one is ambiguous, ask.
