---
name: park
description: Park a blocked task — run /save, stamp what would unblock it, then set the task down in $WORK_PARKED/<slug>/ so another task can start without losing this one's plan, history and handoff. Use when a task cannot proceed and you want to work on something else meanwhile.
---

# Park

Set a blocked task down without losing it. `/park <slug>` saves the session, stamps the blocker and
moves `$WORK_CURRENT` to `$WORK_PARKED/<slug>/`, leaving the live directory empty for `/start`.
**This is not `/done`.** `/done` is for finished work; everything `/park` moves comes back via
`/load <slug>`. The alternatives are a blocked task squatting in the live directory, or an archive
README claiming an outcome that never happened.

## 0. Where work lives

```bash
eval "$(.claude/bin/task.sh paths)" && .claude/bin/task.sh pull
```

Both paths are inside the `.claude/` repository, never the branch you are coding on. On a shared
install an unrecognised git email stops here — ask whose it is, never guess.

## 1. Name the slug

`[a-z0-9-]` only; with no argument, propose one from the plan's objective and confirm it. **Parked
slugs carry no date prefix** — `work/archive/` is a chronological record, but a parked task is live
and takes its date from the plan it still carries.

## 2. Save first — the whole of `/save`, not a subset

Run `/save` to completion first, and if it stops to ask something, let it. The loose-thread sweep
matters more here than in an ordinary save — whatever is half-decided is about to sit untouched for
days — and `handoff.md` gets written for a reader who has forgotten everything.

## 3. Stamp `handoff.md` with what would unblock it

Add `**Blocked on:** <the concrete event that would make this workable again>` directly under the
handoff's heading.

**Name an event, not a feeling.** "Waiting on review" is not a blocker; "PR #482 merging" is. The
test: could someone else read the line and tell you the moment it came true? The session brief
prints it beside the slug at every session start, so a bad one is noise until the task returns. If
nothing concrete would unblock it, the task is deprioritized rather than blocked — `/done` with an
honest outcome, or `work/deferred.md`.

## 4. Move it, then commit

```bash
.claude/bin/task.sh park <slug>
.claude/bin/task.sh commit "park: <slug> — blocked on <the event>"
```

`park` refuses a slug already parked (ask for another; never merge two task directories), a slug
outside `[a-z0-9-]`, and a `$WORK_CURRENT` with no `plan.md`. `commit` pushes when the docs clone
has an `origin`: a park that never reaches it looks parked here and simply missing on the other
machine. **On a rejected push, do not force** — report and stop.

## 5. Report, then stop

Four lines: what was parked and under which slug; what it is blocked on, quoted from the stamp;
what else is parked, so the pile is visible before it is a surprise; and that `/start` is free while
`/load <slug>` brings this one back. Do not start the next task as part of `/park` — running the two
decisions together is how the next task inherits the last one's framing.

## Constraints

- **Never park without saving**, and **never park a finished task** — whoever finds it will read it
  as unfinished. Finished work is `/done`.
- **Do not edit `plan.md` to reflect being blocked.** The plan stays a task list; the blocker lives
  in `handoff.md`, where `/load` and the session brief both look for it.
