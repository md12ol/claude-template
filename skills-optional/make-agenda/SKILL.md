---
name: make-agenda
description: Turn work/collab.md and the tracker's open needs-ruling issues into a meeting agenda at work/meetings/<YYYY-MM-DD>.md, one section per unsettled item, each with a status, a proportionate brief, and questions that can be answered by picking. Rerunnable; a second call folds in items raised since the first without touching anything a human has edited. Use when preparing for a joint working session, or when new collab items land before one starts.
---

# Make agenda

Read `collab.md` and the tracker, decide what actually needs everyone in a room, and write it out as
a file `/start-meeting` can walk. The agenda is **derived**: the sources stay the source of truth and
this skill writes nothing to them beyond §2's status changes. It is the judgement-heavy one of the
three: an agenda that statuses a settled item as `Decide` wastes the meeting's scarcest resource, and
one whose questions need `collab.md` open has failed.

## 0. Set up, and resolve the target

Pull first: a stale copy is how a meeting gets prepared from a file missing its last three items.

```bash
eval "$(.claude/bin/task.sh paths)"      # TRACKER_CLI, TRACKER_REPO, NEEDS_RULING_LABEL, ...
git -C .claude pull --ff-only
git -C .claude rev-parse --short HEAD    # goes in the header; a rerun diffs against it
```

`/make-agenda [YYYY-MM-DD]`, defaulting to today. Target: `work/meetings/<date>.md`, **no owner in
the path**, the same reasoning that keeps `work/archive/` shared.

| Target file | This run is |
|---|---|
| missing | a first build |
| `Status: prepared` | a **rerun**, see §4 |
| `Status: executed` | **stop.** `/end-meeting` has run against it. Offer a new date |

## 1. The second source: open `NEEDS_RULING_LABEL` issues

**When `TRACKER_CLI` is `none`, skip this section** and say so in one line: tracker steps skipped,
`collab.md` is the only source. Otherwise a pending design decision is a tracker issue, so both
sources feed the agenda. The generic shape, then the two CLIs:

    <TRACKER_CLI> issue list --label <NEEDS_RULING_LABEL> --state open

```bash
gh   issue list --repo "$TRACKER_REPO" --state open --label "$NEEDS_RULING_LABEL" --json number,title,body,milestone
glab issue list --repo "$TRACKER_REPO" --label "$NEEDS_RULING_LABEL"      # open by default
```

Such an issue is an agenda item like any other and takes one of the same six statuses. Two
differences: its **brief is its own body**, which already states the problem and what must be ruled,
so compress rather than rewrite; and its **milestone is its urgency**, so it orders ahead of one
sitting in a backlog milestone. Record the issue numbers in the header, so a rerun sees what is new.
**Never edit an issue here**: this skill is as read-only toward the tracker as toward `collab.md`.

## 2. Sweep what does not need the meeting

Find the items **already settled in their own thread**, asked, answered, visibly agreed, nothing
outstanding. Settle those in place and name them in the header rather than putting them in front of
people twice; a status change is the only writing this skill does to `collab.md`.

## 3. Classify every remaining item

Exactly one status each. Getting this right is the whole skill:

| Status | Means | The question to write |
|---|---|---|
| **Decide** | genuinely open; the work is blocked or would be wasted | the actual choice, with the live options named |
| **Ratify** | someone has proposed and built to an answer; it needs a yes | "confirm, or push back on X" |
| **Acknowledge** | a decision already taken that binds someone else's practice | "read and acknowledge", no choice offered |
| **FYI** | worth knowing, needs nothing | none |
| **Park** | real, but cannot be decided yet | what would have to be true first |
| **Close** | overtaken, duplicated, or answered elsewhere | "close, or say why not" |

**Order: blockers first**, then Decide → Ratify → Acknowledge → FYI → Close, and within a status the
tracker items by milestone, soonest first. Deviate only for a reason stated in the header.

## 4. Write the file

```markdown
# Meeting: <YYYY-MM-DD>
**Present:** <names>
**Source:** `work/collab.md` at `<SHA>`, items <list>; issues <numbers, or "tracker skipped">
**Status:** prepared
**Swept before this agenda was built:** <items settled in §2, or "none">

## The map
| Status | Items | Count |

## <N>. <item title>
**Status:** Decide
**Raised:** <date> - <author>
<A brief PROPORTIONATE to the decision: two lines for a small one; for a large one, what is at
stake, what has been tried, what each option costs. Never a summary that sends a reader to the source.>
**Question:** <answerable by picking>   (a) <option>   (b) <option>
**Response:**
_(fill this in by hand before /end-meeting)_

## Other Notes
_(Written by hand: anything decided that was not one of the items above.)_
```

**The file always ends with `## Other Notes`, even empty.** A process note that belongs to no single
item goes there rather than distorting an item's `Response`, and `/end-meeting` reads it as real
instruction, exactly like a `Response` block.

**On a rerun:** diff `collab.md` against the header's SHA, re-list the open issues, fold in what is
new, update the map and the SHA, and **touch nothing carrying a written `Response`** or visibly
edited by a human; that costs more than the items it adds.

## Constraints

- **Never edit an item's body in `collab.md`.** Status changes from §2 only.
- **Never write to the tracker at all**, not a comment, not a label, not a close.
- **Never invent a question nobody raised.** If an item needs a decision it does not name, say so
  in the brief and ask whether to add it.
- **Every item gets a `Response` block**, `FYI` and `Close` included. `/end-meeting` stops on an
  empty one, deliberately.
- **Do not decide anything here.** This skill prepares; it does not rule.
