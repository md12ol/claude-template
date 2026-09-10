---
name: make-agenda
description: Turn work/collab.md into a meeting agenda at work/meetings/<YYYY-MM-DD>.md — one section per unsettled item, each with a status, a proportionate brief, and questions that can be answered by picking. Rerunnable; a second call folds in items raised since the first without touching anything a human has edited. Use when preparing for a joint working session, or when new collab items land before one starts.
---

# Make agenda

Read `collab.md`, decide what actually needs everyone in a room, and write it out as a file
`/start-meeting` can walk. The agenda is a **derived document** — `collab.md` stays the source of
truth, and **this skill never edits it**.

**This is the judgement-heavy skill of the three.** The value is not in listing the items; it is in
classifying them correctly and writing questions that can be answered by picking rather than by
going back to the source. An agenda that statuses a settled item as `Decide` wastes the meeting's
scarcest resource, and one whose questions cannot be answered without re-reading `collab.md` has
failed at its only job.

## 0. Set up

Work where `collab.md` actually lives, and pull first. A stale copy is how a meeting gets prepared
from a file missing the last three items raised.

```bash
git -C .claude pull --ff-only
git -C .claude rev-parse --short HEAD    # record this; a rerun diffs against it
```

**Record that SHA.** It goes in the agenda header and it is what a rerun compares against.

## 1. Resolve the date and the target

`/make-agenda [YYYY-MM-DD]`, defaulting to today. Target: `work/meetings/<date>.md`.

**No owner in the path.** A meeting belongs to everyone in it, the same reasoning that keeps
`work/archive/` shared.

| Target file | This run is |
|---|---|
| missing | a first build |
| `Status: prepared` | a **rerun** — see §4 |
| `Status: executed` | **stop.** `/end-meeting` has run against it. Offer a new date |

## 2. Sweep what does not need the meeting

Before classifying anything, look for items that are **already settled in their own thread** — the
question was asked and answered, everyone visibly agreed, and nothing is outstanding. Settle those
in place and say so in the agenda header rather than putting them in front of people a second time.

This is the only writing this skill does to `collab.md`, and it is a status change, not a rewrite.
Never change anyone's words.

## 3. Classify every remaining item

Exactly one status each. Getting this right is the whole skill:

| Status | Means | The question to write |
|---|---|---|
| **Decide** | genuinely open; the work is blocked or would be wasted | the actual choice, with the live options named |
| **Ratify** | someone has proposed and built to an answer; it needs a yes | "confirm, or push back on X" |
| **Acknowledge** | a decision already taken that binds someone else's practice | "read and acknowledge" — no choice offered |
| **FYI** | worth knowing, needs nothing | none |
| **Park** | real, but cannot be decided yet | what would have to be true first |
| **Close** | overtaken, duplicated, or answered elsewhere | "close, or say why not" |

**Order: blockers first**, then Decide → Ratify → Acknowledge → FYI → Close. Deviate only for a
reason you state in the header, such as a demonstration everyone needs to see before two of the
ratifications make sense.

## 4. Write the file

```markdown
# Meeting — <YYYY-MM-DD>

**Present:** <names>
**Source:** `work/collab.md` at `<SHA>`, items <list>
**Status:** prepared
**Swept before this agenda was built:** <items settled in §2, or "none">

## The map

| Status | Items | Count |
|---|---|---|

## <N>. <item title>

**Status:** Decide
**Raised:** <date> — <author>

<A brief PROPORTIONATE to the decision. Two lines for a small one. For a large one: what is
actually at stake, what has been tried, and what each option costs. Never a summary of the item
that makes a reader open collab.md anyway.>

**Question:** <answerable by picking>
  (a) <option>
  (b) <option>

**Response:**
_(fill this in by hand before /end-meeting)_
```

**On a rerun:** diff `collab.md` against the SHA in the header, fold in what is new, update the map
and the SHA, and **touch nothing that already has a written `Response`** or that a human has
visibly edited. A rerun that overwrites someone's answer costs more than the items it adds.

## Constraints

- **Never edit an item's body in `collab.md`.** Status changes from §2 only.
- **Never invent a question nobody raised.** If an item needs a decision the item does not name,
  say so in the brief and ask whether to add it.
- **Every item gets a `Response` block**, including `FYI` and `Close`. `/end-meeting` stops on an
  empty one, deliberately.
- **Do not decide anything here.** This skill prepares; it does not rule.
