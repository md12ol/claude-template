---
name: park
description: Park a blocked task — run /save, then move the live task directory into work/parked/<slug>/ so another task can start without losing this one's plan, history and handoff. Use when a task cannot proceed (waiting on a review, an unmerged change, an unanswered question, someone else's deploy) and you want to work on something else meanwhile.
---

# Park

Set a blocked task down without losing it. `/park <slug>` saves the session, then moves
`$WORK_CURRENT` to `$WORK_PARKED/<slug>/`, leaving the live directory empty for the next `/start`.

**This is not `/done`.** `/done` is for finished work and archives to `work/archive/`, which is
shared history. `/park` is for **unfinished** work that cannot proceed right now, and everything it
moves is expected to come back via `/load <slug>`.

**The alternative it replaces is worse than it looks.** Without it, a blocked task either sits in
the live directory blocking `/start` — so the next piece of work happens with no plan at all — or
gets closed with `/done`, which writes an archive README claiming an outcome that did not happen.
Both are silent.

## 0. Resolve where work lives — read it, do not assume it

Live task paths depend on how this `.claude/` is configured. **Read the configuration; never guess
from what is on disk.**

```bash
. .claude/hooks/lib.sh && load_conf && resolve_owner
echo "$WORK_CURRENT"      # work/current  OR  work/<owner>/current
echo "$WORK_PARKED"       # work/parked   OR  work/<owner>/parked
```

On a **shared** install the owner is `git config user.email` matched against `work/owners.txt`, the
only copy of that table. An empty `WORK_CURRENT` means the address is missing: **stop and ask**,
never pick the likeliest person — writing into someone else's directory is silent, and surfaces only
when they open a directory they didn't expect to have work in.

Everything below writes `$WORK_CURRENT` and `$WORK_PARKED`, and every one of those paths is inside
the **`.claude/` repository**, not the branch this session is coding on. Pull it first; the main
tree's checked-out branch is never switched, stashed or touched.

```bash
git -C .claude pull --ff-only
```

## 1. Name the slug

`/park <slug>`. With no argument, propose one from the plan's objective and confirm it.

**Parked slugs carry no date prefix.** `work/archive/` uses `<YYYY-MM>_<slug>` because it is a
chronological record; a parked task is live and takes its date from the plan it still carries. A
date in the name would say when it was parked, which is the least useful fact about it.

Refuse a slug that already exists in `$WORK_PARKED` and ask for another. Never merge two task
directories.

## 2. Save first — the whole of `/save`, not a subset

Run `/save` to completion before moving anything. Every part of it earns its place here:

- The **loose-thread sweep** matters more when parking than in an ordinary save. Whatever is
  half-decided in this session is about to sit untouched for days, and the sweep is the only thing
  that catches it.
- `history.md` gets the session entry, so the record does not stop mid-thought.
- `handoff.md` gets written for a reader who has forgotten everything — which, after a park, is
  exactly who shows up.

If `/save` stops to ask you something, let it. Parking on top of an incomplete save is how a task
comes back missing the reason it was parked.

## 3. Stamp `handoff.md` with what would unblock it

Add this line, right under the heading:

```
**Blocked on:** <the concrete event that would make this workable again>
```

**Name an event, not a feeling.** "Waiting on review" is not a blocker; "PR #482 merging, or its
author saying the API is final" is. The test: could someone else read this line and tell you the
moment it came true? The session brief prints this line beside every parked slug, so a bad one is
noise on every session start until the task returns.

If nothing concrete would unblock it, the task is probably not blocked — it is deprioritized, which
is a different thing and usually means `/done` with an honest outcome, or an entry in
`work/deferred.md`.

## 4. Move it

```bash
mkdir -p "$WORK_PARKED"
mv "$WORK_CURRENT" "$WORK_PARKED/<slug>"
mkdir -p "$WORK_CURRENT"      # left empty, so /start has somewhere to write
```

Check the parked copy is a task directory and not a directory containing one — if `<slug>` already
existed, `mv` will have nested it silently:

```bash
ls "$WORK_PARKED/<slug>"      # expect plan.md and handoff.md, not another directory
```

That last `mkdir` is why **`/load <slug>` must `rmdir` before it moves the task back**: unparking
into an existing directory nests it one level down, and nothing errors. `/load` §0.5 handles it;
do not hand-roll the reverse of this step.

Then confirm the live directory is genuinely empty — `/start` refuses to run while it is not, and a
stray `plan_superseded.md` left behind is the usual culprit:

```bash
ls -A "$WORK_CURRENT"
```

## 5. Commit and push, if the directory is tracked

Same rule and same narrow exception as `/save` §10: `$WORK_CURRENT` and `$WORK_PARKED` only, and
only when they are tracked. A park that never reaches `origin` is worse than an unsaved one — the
task looks parked on this machine and simply missing on the other.

```bash
git -C .claude add -A "$WORK_CURRENT" "$WORK_PARKED"
git -C .claude commit -m "park: <slug> — blocked on <the event>"
git -C .claude push
```

## 6. Report, then stop

Four lines:

- what was parked, and the slug it is under
- what it is blocked on, quoted from the stamp
- what else is parked, so the pile is visible before it becomes a surprise
- that `/start` is now free, and `/load <slug>` brings this one back

Do not start the next task as part of `/park`. Parking and starting are two decisions, and running
them together is how the next task inherits the last one's framing.

## Constraints

- **Never park without saving.** The whole value is that the task comes back intact.
- **Never park a finished task.** If the work is done, it is `/done` — a parked task that is
  actually complete will be re-read as unfinished by whoever finds it.
- **Never park into another owner's directory**, on a shared install. If `resolve_owner` came back
  empty, stop and ask.
- **Do not edit `plan.md` to reflect being blocked.** The plan stays a task list; the blocker lives
  in `handoff.md`, which is where `/load` and the session brief both look for it.
