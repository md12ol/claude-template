---
name: load
description: Start a session on the current task — read .claude/$WORK_CURRENT/handoff.md, plan.md, decisions.md and hotfixes.md, verify them against the actual repo state, and report where things stand before doing any work. Use at the start of a session, when resuming a task, or when the user asks where things are.
---

# Load

Pick up the current task. This is step 5 of the loop:

1. New task
2. `/start`
3. Work
4. `/save`
5. **`/load`** ← you are here
6. Work
7. Finished? → step 8. Not finished? → step 4.
8. `/done <slug>`

`/save` wrote `$WORK_CURRENT/handoff.md` for you. Your job is to consume it, **check it is still true**,
and report — then stop and wait. Do not start work as part of `/load`.

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

## 0.5. Resume a parked task, if you were given a slug

`/load` with no argument resumes what is in `$WORK_CURRENT`. `/load <slug>` brings back a task from
`$WORK_PARKED/<slug>/`.

**Unparking is a swap, and it is done in one go.** If `$WORK_CURRENT` is non-empty, park it first
(`/park <its-slug>`) and only then move `<slug>` in. Never leave two task directories live: the
session brief, `/save` and `/done` all read `$WORK_CURRENT` and there is no tiebreak.

```bash
[[ -n "$(ls -A "$WORK_CURRENT" 2>/dev/null)" ]] && echo "park the live task first"
rmdir "$WORK_CURRENT" 2>/dev/null          # see below — this line is load-bearing
mv "$WORK_PARKED/<slug>" "$WORK_CURRENT"
```

**The `rmdir` is not tidying — leaving it out corrupts the restore.** `/park` recreates the live
directory empty, so `$WORK_CURRENT` normally *exists* when you unpark, and `mv src dst` onto an
existing directory moves `src` **inside** it: `current/<slug>/plan.md` instead of
`current/plan.md`. Nothing errors, the session brief then reports no active task because it looks
one level up, and the task reads as lost. `rmdir` only succeeds on an empty directory, so it cannot
destroy a live task even if the guard above is skipped.

Confirm the shape afterwards rather than assuming it:

```bash
ls "$WORK_CURRENT"                          # expect plan.md and handoff.md, not a directory
```

Then read the handoff's `**Blocked on:**` line **first** — it names the event that must have
happened for this task to be workable. If it hasn't, say so and stop rather than starting work that
parks again in ten minutes.

## 0.6. Check for cross-machine divergence — before reading anything as true

Only when `project.conf` says `MACHINES="multi"`. `/save` stamps `handoff.md` with the machine and
the SHA it was written against:

```
**Machine:** <hostname> · saved <YYYY-MM-DD HH:MM> · <SHA>
```

Compare that SHA with what the repo is on now, and compare the hostname with this machine's.

- **Same machine, SHA is an ancestor of HEAD** — normal. Continue.
- **Different machine** — normal on a multi-machine install, but say so in the report. It is the
  single best predictor of a handoff describing a tree that no longer exists.
- **The SHA is not in this repo's history**, or the working-docs clone has commits `origin` does
  not — **stop and report.** Do not merge, reset or "reconcile". Two machines have written to the
  same live plan, which is rewritten in place, so no merge strategy recovers the intent. Show both
  sides and let the user choose.

A missing stamp is not a divergence; it means the last save predates this convention. Say so once
and carry on.

## 1. Read, in this order

1. `.claude/$WORK_CURRENT/handoff.md` — the instruction from the last session. This is the primary input.
2. `.claude/$WORK_CURRENT/plan.md` — the objective and task status.
3. `.claude/work/decisions.md` — at least the most recent entries. **Do not re-litigate anything
   recorded here**; if you think a past decision is wrong, say so rather than quietly doing
   something else.
4. `.claude/work/hotfixes.md` — temporary code you might otherwise mistake for a bug, or delete.
5. `.claude/work/traps.md` — workspace gotchas. Cheap, and each is there because it already cost
   someone a session.
6. `.claude/work/issues.md` — only to notice what's logged, so you don't re-report it.
7. `.claude/work/collab.md`, if it exists — the **Open** items. Each is a decision on one side that
   overrides work on the other, and acting against one is how someone's work gets overwritten.

`$WORK_CURRENT/plan_superseded.md` is reference only. Don't read it on load, and never action anything in
it — it holds the original wording of tasks that are already done.

If `$WORK_CURRENT/` is empty or has no `plan.md`, there is **no active task**. Say so and point at
`/start`. Do not invent one.

**If the repo is shared and this session follows a merge**, read the *tail* of the persistent docs
first: `merge=union` never reports a conflict, so two people editing one entry yields both versions
interleaved. A doubled or self-contradicting entry is a merge artefact to fix, not a decision to
follow.

## 2. Verify the handoff against reality

The handoff may be days old. Treat it as a claim to check, not a fact. Confirm before relying on it:

- **Branches.** `git branch --show-current` for every repo the work spans — see `CLAUDE.md`'s repo
  layout. The handoff's manifest may name a branch you are no longer on.
- **Working tree.** `git status --short` per repo. Files may have been committed, reverted, or
  further edited since. Conflicts recorded as unresolved may now be resolved — or vice versa.
- **Specific claims.** Where the handoff says a file is in some state ("unresolved conflict",
  "stub", "not yet written"), open it and confirm. Cheap, and exactly the class that goes stale.
- **`[~]` items.** Done-but-unverified: check whether the `Verify by:` has since happened. Never
  promote `[~]` to `[x]` on inference — only on evidence, or on the user saying they ran it.

Where reality and the docs disagree, **the repo wins**. Report the discrepancy; don't silently
patch the docs to match, and don't silently follow the stale version.

## 3. Report and stop

Give the user a short brief:

- **Where things stand** — 2–4 sentences, from the handoff, corrected by what you verified.
- **Anything that changed since the handoff was written** — explicitly, or "nothing changed".
- **Start here** — the next concrete action the handoff names, or the first `[ ]` item in the plan.
- **Live traps** — unverified `[~]` items (**oldest first, with their age**), load-bearing hotfixes
  in the code you're about to touch, known-broken state.
- **Blockers** — unanswered open questions in the plan that gate the next action.

Then **wait for the user**. `/load` orients; it does not begin work. Confirm even when the next
action is obvious and small — priorities may have moved since the handoff was written, which is
exactly what the docs cannot know.

## Constraints

- Read-only. `/load` changes no files, including the docs — if they're wrong, report it and let
  `/save` or the user fix it.
- Don't commit, push, or start edits.
- Respect `CLAUDE.md`'s rule on who runs the environment. If verifying something requires a run you
  are not allowed to make, say what you need and ask the user to run it.
