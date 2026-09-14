---
name: load
description: Pick up the current task: read $WORK_CURRENT/handoff.md, plan.md, decisions.md and traps.md, check them against the actual repo state, and report where things stand before doing any work. Use at the start of a session, when resuming a task, or when the user asks where things are.
model: sonnet
---

# Load

`/save` wrote `$WORK_CURRENT/handoff.md` for you. Consume it, **check it is still true**, report,
then stop and wait. `/load` orients; it does not begin work.

`/load <slug>` resumes a parked task instead of what is live.

## 0. Where work lives

```bash
eval "$(.claude/bin/task.sh paths)" && .claude/bin/task.sh pull
```

Both paths are inside the `.claude/` repository, never the branch you are coding on. On a shared
install an unrecognised git email stops here; ask whose it is, never guess.

## 1. Resolve which task, before reading anything as true

- **A slug was passed** → that parked task. If it is not in `$WORK_PARKED`, list what is parked and
  stop; never guess at a near match.
- **No slug and `$WORK_CURRENT/plan.md` exists** → the active task. The parked ones are not touched,
  but **name them and their blockers** in the report, and say whether anything you verify in §4 has
  unblocked one: that is the only thing a parked task gets from a session it is not part of.
- **No slug, `$WORK_CURRENT` empty, exactly one parked** → unpark it, and say plainly that you did.
- **No slug, `$WORK_CURRENT` empty, several parked** → **ask**, listing each slug with its blocker,
  so the choice is answerable without opening anything.
- **The owner's directory does not exist at all** → say which of the two this is, because they look
  alike and are not: nobody has started a task on this machine yet, or the install is incomplete
  (no `work/owners.txt` entry, `/setup` never finished).
- **Nothing live and nothing parked** → there is no task. Say so, point at `/start`, invent nothing.

### Unparking is a swap, and it is reported both ways

If `$WORK_CURRENT` is non-empty, there is a live task: `/park <its-slug>` it first, never leaving
two task directories live, because `/save`, `/done` and the session brief all read `$WORK_CURRENT`
there is no tiebreak. A session that thinks it parked nothing will `/save` over the wrong plan, so
name both tasks in the report.

```bash
.claude/bin/task.sh unpark <slug>
.claude/bin/task.sh commit "load: unparked <slug>"
```

`unpark` refuses when `$WORK_CURRENT` is non-empty or the slug is not parked, and prints the
handoff's `**Blocked on:**` line; `commit` pushes the move so the other machine sees the same desk.
**Read the blocker line first**: it names the event that had to happen for this task to be workable,
and if it has not, say so rather than starting work that parks again in ten minutes.

## 2. Check for cross-machine divergence

```bash
.claude/bin/task.sh check-stamp
```

It compares the handoff's `Machine:` stamp with this machine and this repo: nothing on a
single-machine install, "no stamp" when the save predates the convention (not a divergence, say so
once and carry on), otherwise which machine saved and whether the SHA is in history.

**Exit 1 means stop and report**, in one of three shapes: the SHA is not in this repo's history; the
docs clone has commits `origin` lacks; or the docs clone has uncommitted changes, meaning a previous
session ended before its save reached the push and those changes are probably the real state. The
first two are two machines writing to one live plan, rewritten in place, so no merge strategy
recovers the intent. Show both sides, let the user choose, and **never merge, reset or reconcile.**
A different machine with everything in history is normal: mention it, since it is the best predictor
of a handoff describing a tree that no longer exists.

## 3. Read, in this order

1. `$WORK_CURRENT/handoff.md`: the instruction from the last session. The primary input.
2. `$WORK_CURRENT/plan.md`: objective and task status.
3. `work/decisions.md`: the recent entries at least. **Do not re-litigate anything recorded here**;
   if you think one is wrong, say so rather than quietly doing something else.
4. `work/hotfixes.md`, or `.claude/bin/task.sh temporary` where `TRACKER_FIRST="yes"`: temporary
   code you might otherwise mistake for a bug, or delete.
5. `work/traps.md`: each one is there because it already cost someone a session.
6. `work/issues.md`, or the tracker's open list where `TRACKER_FIRST="yes"` (the CLI is
   `TRACKER_CLI` in `project.conf`), only to notice what is logged, so you don't re-report it.
7. `work/collab.md`, if it exists: the **Open** items. Each is a decision on one side that
   overrides work on the other, and acting against one is how someone's work gets overwritten.

On a shared install run `.claude/bin/task.sh audit` and report what it prints: open items nobody has
answered, oldest first, and archived items with no recorded disposition. **Report them; never settle
one yourself.** `.claude/bin/task.sh collab-next` gives the next free item number, so nobody guesses
it from the end of one file. `plan_superseded.md` is reference only: don't read it on load, and
never action anything in it.

**If this session follows a merge on a shared install**, read the *tail* of the persistent docs
first: `merge=union` never reports a conflict, so two people editing one entry yields both versions
interleaved. A doubled or self-contradicting entry is a merge artefact, not a decision to follow.

## 4. Verify the handoff against reality

The handoff may be days old. Treat it as a claim to check:

- **Branches**: `git branch --show-current` for every repo the work spans. The manifest may name a
  branch you are no longer on.
- **Working tree**: `git status --short` per repo. Files may have been committed, reverted or
  edited since; recorded conflicts may now be resolved, or the reverse.
- **Specific claims**: where the handoff says a file is in some state ("unresolved conflict",
  "stub", "not yet written"), open it. Cheap, and exactly the class that goes stale.
- **`[~]` items**: check whether the `Verify by:` has since happened. Never promote `[~]` to `[x]`
  on inference; only on evidence, or on the user saying they ran it.

Where reality and the docs disagree, **the repo wins**. Report the discrepancy; don't silently patch
the docs to match, and don't silently follow the stale version.

## 5. Report, then stop

- **Where things stand**: 2–4 sentences, corrected by what you verified, and **what changed**
  since it was written, explicitly, or "nothing changed".
- **Start here**: the next concrete action the handoff names, or the first `[ ]` item in the plan.
- **Live traps**: `[~]` items oldest first with their age, hotfixes or `TEMPORARY (` markers in
  the code you are about to touch, and the plan's open questions that gate the next action.
- **Parked tasks and any swap**: one line each, slug, blocker, and whether it now looks unblocked.

Then **wait for the user**, even when the next action looks obvious and small. Priorities may have
moved since the handoff was written, which is exactly what the docs cannot know.

## Constraints

- Read-only apart from §1's unpark: `/load` edits no file, the docs included. If they are wrong,
  report it and let `/save` or the user fix it; don't commit, push or start edits beyond that.
- Respect `CLAUDE.md`'s rule on who runs the environment. If verifying something needs a run you
  are not allowed to make, say what you need and ask.
