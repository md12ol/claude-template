---
name: start-meeting
description: Go on standby beside a prepared agenda at work/meetings/<YYYY-MM-DD>.md and answer questions about it on demand, item by item, from collab.md, the tracker, the working docs, the code and git history, while the people in the meeting write their answers into the file by hand. Read-only; it changes no file at all. Use when working through a prepared agenda.
---

# Start meeting

Load the prepared agenda, report the map, then **wait**. People work through it by typing an item
number and a question; this skill answers from the sources. It asks nothing, decides nothing and
**writes no file**: the `Response` blocks are filled in by hand, by a person, in an editor.

**This is a research desk, not an interviewer.** Walking the items and writing down the answers
inverts who holds the decision, and records a conversation rather than considered text. What this is
better at is what it now does: pulling facts out of a long `collab.md`, the decision log, the code
and git history, fast and with citations.

## 0. Set up

```bash
eval "$(.claude/bin/task.sh paths)"      # TRACKER_CLI, TRACKER_REPO, NEEDS_RULING_LABEL, ...
git -C .claude pull --ff-only
```

`/start-meeting [YYYY-MM-DD]`, defaulting to today. Then check the header:

| `Status:` | Do this |
|---|---|
| `prepared` | normal start, go to §1. **Do not stamp anything**, the header is not yours to write |
| `executed` | **stop.** `/end-meeting` has already run. Offer `/make-agenda` for a new date |
| file missing | **stop.** Run `/make-agenda` first. Do not improvise an agenda on the spot |

No `in progress` status, no cursor: **an item with an empty `Response` block is one not yet
answered**, which is all a hand-edited file needs to be resumable.

## 1. Report the map, once

Read `work/pipeline_backlog.md` alongside the agenda. Then five lines, and stop talking: how many
items, split by status · which are blockers · anything in `pipeline_backlog.md` marked
`Needs discussion.` · how many `Response` blocks are filled in · that you are on standby and want an
item number and a question. Then **wait.** Do not summarize item 1, or suggest where to start.

## 2. Answer on demand

Answer from the sources, in order of preference: **`collab.md` and `collab_settled.md`** (the thread
itself, and anything the same question was asked in before, quote it), then **`decisions.md`**
(whether it was already decided, and why), then **the code and its history** (what is true now, as
opposed to what was agreed), and last **your own reading**, marked as such.

**For an item that came from a `NEEDS_RULING_LABEL` issue the issue is the source**, and `collab.md`
may hold nothing on it. Read the body, the comments and what it blocks, generic shape first:

    <TRACKER_CLI> issue view <n>

```bash
gh   issue view <n> --repo "$TRACKER_REPO" --json title,body,comments,milestone,labels
glab issue view <n> --repo "$TRACKER_REPO" --comments
```

When `TRACKER_CLI` is `none` there are no such items: say so once, and read `collab.md` alone.

**Cite every claim** with a file and a line, an issue number, or a commit; an uncited answer becomes
a decision nobody can trace. **Say "I don't know" plainly**: the failure here is a confident
synthesis of three half-related threads, delivered when nobody has time to check it. **When the
sources disagree, say so and stop**: the contradiction is itself the finding, and often why the item
was raised.

## Constraints

- **Write nothing. No file, no stamp, no status change.** This is the whole design.
- **Never touch the tracker either.** No comment, no label, no milestone, no close, however obviously
  right it looks while you are reading it. `/end-meeting` owns what a ruling changes.
- **Do not answer a question that was not asked**, and do not volunteer an opinion on an item.
- **Do not advance to the next item.** The people in the room decide the order.
- If asked to record something, say that `Response` blocks are written by hand and that
  `/end-meeting` reads them.
