---
name: make-agenda
description: Turn work/collab.md into a meeting agenda at work/meetings/<YYYY-MM-DD>.md — one section per unsettled item, each with a status, a proportionate brief, and questions that can be answered by picking. Rerunnable; a second call folds in items raised since the first without touching anything a human has edited. Use when preparing for a joint working session, or when new collab items land before one starts.
---

# Make agenda

Read `collab.md`, decide what actually needs everyone in a room, and write it out as a file
`/start-meeting` can walk. The agenda is **derived**: `collab.md` stays the source of truth and this
skill writes nothing to it beyond §1's status changes. It is the judgement-heavy one of the three —
an agenda that statuses a settled item as `Decide` wastes the meeting's scarcest resource, and one
whose questions need `collab.md` open has failed.

## 0. Set up, and resolve the target

Pull first: a stale copy is how a meeting gets prepared from a file missing its last three items.

```bash
git -C .claude pull --ff-only
git -C .claude rev-parse --short HEAD    # goes in the header; a rerun diffs against it
```

`/make-agenda [YYYY-MM-DD]`, defaulting to today. Target: `work/meetings/<date>.md` — **no owner in
the path**, the same reasoning that keeps `work/archive/` shared.

| Target file | This run is |
|---|---|
| missing | a first build |
| `Status: prepared` | a **rerun** — see §3 |
| `Status: executed` | **stop.** `/end-meeting` has run against it. Offer a new date |

## 1. Sweep what does not need the meeting

Find the items **already settled in their own thread** — asked, answered, visibly agreed, nothing
outstanding. Settle those in place and name them in the header rather than putting them in front of
people twice; a status change is the only writing this skill does to `collab.md`.

## 2. Classify every remaining item

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
reason stated in the header.

## 3. Write the file

```markdown
# Meeting — <YYYY-MM-DD>
**Present:** <names>
**Source:** `work/collab.md` at `<SHA>`, items <list>
**Status:** prepared
**Swept before this agenda was built:** <items settled in §1, or "none">

## The map
| Status | Items | Count |

## <N>. <item title>
**Status:** Decide
**Raised:** <date> — <author>
<A brief PROPORTIONATE to the decision: two lines for a small one; for a large one, what is at
stake, what has been tried, what each option costs. Never a summary that sends a reader to collab.md.>
**Question:** <answerable by picking>   (a) <option>   (b) <option>
**Response:**
_(fill this in by hand before /end-meeting)_
```

**On a rerun:** diff `collab.md` against the header's SHA, fold in what is new, update the map and
the SHA, and **touch nothing carrying a written `Response`** or visibly edited by a human — that
costs more than the items it adds.

## Constraints

- **Never edit an item's body in `collab.md`.** Status changes from §1 only.
- **Never invent a question nobody raised.** If an item needs a decision it does not name, say so
  in the brief and ask whether to add it.
- **Every item gets a `Response` block**, `FYI` and `Close` included. `/end-meeting` stops on an
  empty one, deliberately.
- **Do not decide anything here.** This skill prepares; it does not rule.
