---
name: load
description: Pick up the current task — read $WORK_CURRENT/handoff.md, plan.md, decisions.md and traps.md, check them against the actual repo state, and report where things stand before doing any work. Use at the start of a session, when resuming a task, or when the user asks where things are.
---

# Load

`/save` wrote `$WORK_CURRENT/handoff.md` for you. Consume it, **check it is still true**, report —
then stop and wait. `/load` orients; it does not begin work.

`/load <slug>` resumes a parked task instead of what is live.

## 0. Where work lives

```bash
eval "$(.claude/bin/task.sh paths)" && .claude/bin/task.sh pull
```

Both paths are inside the `.claude/` repository, never the branch you are coding on. On a shared
install an unrecognised git email stops here — ask whose it is, never guess.

## 1. If you were given a slug, unpark it

**Unparking is a swap.** If `$WORK_CURRENT` is non-empty, there is a live task: `/park <its-slug>`
it first — never leave two task directories live, because `/save`, `/done` and the session brief
all read `$WORK_CURRENT` and there is no tiebreak.

```bash
.claude/bin/task.sh unpark <slug>
```

It refuses when `$WORK_CURRENT` is non-empty or the slug is not parked, and it prints the handoff's
`**Blocked on:**` line. **Read that line first.** It names the event that had to happen for this
task to be workable; if it has not, say so and stop rather than starting work that parks again in
ten minutes.

## 2. Check for cross-machine divergence — before reading anything as true

```bash
.claude/bin/task.sh check-stamp
```

It compares the handoff's `Machine:` stamp with this machine and this repo. Prints nothing on a
single-machine install, "no stamp" when the save predates the convention (not a divergence — say so
once and carry on), and otherwise which machine saved and whether the SHA is in history.

**Exit 1 means stop and report.** Either the SHA is not in this repo's history, or the docs clone
has commits `origin` does not: two machines have written to the same live plan, which is rewritten
in place, so no merge strategy recovers the intent. Show both sides and let the user choose. **Never
merge, reset or reconcile.** A different machine with everything in history is normal — mention it
in the report, since it is the best predictor of a handoff describing a tree that no longer exists.

## 3. Read, in this order

1. `$WORK_CURRENT/handoff.md` — the instruction from the last session. The primary input.
2. `$WORK_CURRENT/plan.md` — objective and task status.
3. `work/decisions.md` — the recent entries at least. **Do not re-litigate anything recorded here**;
   if you think one is wrong, say so rather than quietly doing something else.
4. `work/hotfixes.md` — temporary code you might otherwise mistake for a bug, or delete.
5. `work/traps.md` — each one is there because it already cost someone a session.
6. `work/issues.md` — only to notice what is logged, so you don't re-report it.
7. `work/collab.md`, if it exists — the **Open** items. Each is a decision on one side that
   overrides work on the other, and acting against one is how someone's work gets overwritten.

`plan_superseded.md` is reference only: don't read it on load, and never action anything in it.

If `$WORK_CURRENT/` is empty or has no `plan.md`, there is **no active task**. Say so, point at
`/start`, and do not invent one.

**If this session follows a merge on a shared install**, read the *tail* of the persistent docs
first: `merge=union` never reports a conflict, so two people editing one entry yields both versions
interleaved. A doubled or self-contradicting entry is a merge artefact to fix, not a decision to
follow.

## 4. Verify the handoff against reality

The handoff may be days old. Treat it as a claim to check:

- **Branches** — `git branch --show-current` for every repo the work spans. The manifest may name a
  branch you are no longer on.
- **Working tree** — `git status --short` per repo. Files may have been committed, reverted or
  edited since; recorded conflicts may now be resolved, or the reverse.
- **Specific claims** — where the handoff says a file is in some state ("unresolved conflict",
  "stub", "not yet written"), open it. Cheap, and exactly the class that goes stale.
- **`[~]` items** — check whether the `Verify by:` has since happened. Never promote `[~]` to `[x]`
  on inference; only on evidence, or on the user saying they ran it.

Where reality and the docs disagree, **the repo wins**. Report the discrepancy; don't silently patch
the docs to match, and don't silently follow the stale version.

## 5. Report, then stop

- **Where things stand** — 2–4 sentences from the handoff, corrected by what you verified.
- **What changed since it was written** — explicitly, or "nothing changed".
- **Start here** — the next concrete action the handoff names, or the first `[ ]` item in the plan.
- **Live traps** — `[~]` items oldest first with their age, load-bearing hotfixes in the code you
  are about to touch, known-broken state.
- **Blockers** — open questions in the plan that gate the next action.

Then **wait for the user**, even when the next action looks obvious and small. Priorities may have
moved since the handoff was written, which is exactly what the docs cannot know.

## Constraints

- Read-only apart from the unpark in §1: `/load` edits no file, the docs included — if they are
  wrong, report it and let `/save` or the user fix it. Don't commit, push or start edits; the
  unpark's move reaches `origin` with the next `/save`.
- Respect `CLAUDE.md`'s rule on who runs the environment. If verifying something needs a run you are
  not allowed to make, say what you need and ask.
