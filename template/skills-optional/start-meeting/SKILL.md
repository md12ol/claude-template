---
name: start-meeting
description: Go on standby beside a prepared agenda at work/meetings/<YYYY-MM-DD>.md and answer questions about it on demand — item by item, from collab.md, the working docs, the code and git history — while the people in the meeting write their answers into the file by hand. Read-only; it changes no file at all. Use when working through a prepared agenda.
---

# Start meeting

Load the prepared agenda, report the map, and then **wait**. People work through the agenda by
typing an item number and a question; this skill answers it from the sources. It asks nothing,
decides nothing, and **writes no file** — the `Response` blocks are filled in by hand, by a person,
in an editor.

**This is a research desk, not an interviewer.** An earlier design had this skill walk the items,
ask each question as a prompt, and write the answer into the file. That inverts who holds the
decision: the model drives and the humans answer. It also records decisions from a conversation
rather than from considered text, and the difference shows up weeks later when someone asks what
was actually agreed.

What it is genuinely better at is the thing it now does: pulling the relevant facts out of a very
long `collab.md`, the decision log, the code and `git log`, fast and with citations.

## 0. Set up

```bash
DOCS=.claude; [[ -d .claude/.git ]] || DOCS=.
[[ -d "$DOCS/.git" ]] && git -C "$DOCS" pull --ff-only
```

`/start-meeting [YYYY-MM-DD]`, defaulting to today. Then check the header:

| `Status:` | Do this |
|---|---|
| `prepared` | normal start, go to §1. **Do not stamp anything** — the header is not yours to write |
| `executed` | **stop.** `/end-meeting` has already run. Offer `/make-agenda` for a new date |
| file missing | **stop.** Run `/make-agenda` first. Do not improvise an agenda on the spot |

There is no `in progress` status and no cursor. Both existed to make a walked meeting resumable,
and a file people edit by hand is resumable by looking at it: **an item with an empty `Response`
block is one that has not been answered yet.**

## 1. Report the map, once

Read `work/pipeline_backlog.md` alongside the agenda. Then five lines, and stop talking:

- how many items, split by status
- which are blockers
- anything in `pipeline_backlog.md` marked `Needs discussion.`
- how many `Response` blocks are already filled in
- that you are on standby: give an item number and a question

Then **wait.** Do not summarize item 1. Do not suggest where to start.

## 2. Answer on demand

For each question asked, answer from the sources, in this order of preference:

1. **`collab.md` and `collab_settled.md`** — the thread itself, and anything the same question was
   asked in before. Quote it.
2. **`decisions.md`** — whether this was already decided, and what the reasoning was.
3. **The code and `git log`** — what is actually true now, as opposed to what was agreed.
4. **Your own reading** — clearly marked as such, and last.

**Cite every claim** with a file and a line, or a commit. An uncited answer in a meeting becomes a
decision nobody can trace afterwards.

**Say "I don't know" plainly.** The failure mode here is a confident synthesis of three half-related
threads, delivered at the exact moment nobody has time to check it.

**When the sources disagree, say so and stop.** Do not reconcile them. A contradiction between the
decision log and the code is itself the finding, and often the reason the item was raised.

## Constraints

- **Write nothing. No file, no stamp, no status change.** This is the whole design.
- **Do not answer a question that was not asked**, and do not volunteer an opinion on an item.
- **Do not advance to the next item.** The people in the room decide the order.
- If asked to record something, say that `Response` blocks are written by hand and that
  `/end-meeting` reads them.
