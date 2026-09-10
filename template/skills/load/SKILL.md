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

Live task directories depend on how this `.claude/` is configured. **Read the configuration; never
guess from what you see on disk.**

```bash
. .claude/hooks/lib.sh && load_conf && resolve_owner
echo "$WORK_CURRENT"      # work/current  OR  work/<owner>/current
echo "$WORK_PARKED"       # work/parked   OR  work/<owner>/parked
```

| `project.conf` | Live task path | Parked path |
|---|---|---|
| `PEOPLE="solo"` | `work/current/` | `work/parked/` |
| `PEOPLE="shared"` | `work/<owner>/current/` | `work/<owner>/parked/` |

On a **shared** install the owner comes from `git config user.email` matched against
`work/owners.txt` — **the only copy of that table**. If `resolve_owner` returns an empty
`WORK_CURRENT`, the address is not in it: **stop and ask.** Do not pick the likeliest person.
Writing into someone else's directory is silent — the work is neither lost nor found, and it
surfaces only when they open a directory they did not expect to have anything in.

Everything below writes `$WORK_CURRENT` and `$WORK_PARKED` rather than a literal path, so the same
instructions hold either way.

**If `.claude/` is its own clone** (the fork layout — `[[ -d .claude/.git ]]`), every `work/` path
below is inside *that* repository, not the branch this session is coding on. Pull it first:

```bash
[[ -d .claude/.git ]] && git -C .claude pull --ff-only
```

The main tree's checked-out branch is never switched, stashed or touched.

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

**The `rmdir` is not tidying, and leaving it out corrupts the restore.** `/park` recreates the live
directory empty, so `$WORK_CURRENT` normally *exists* when you unpark — and `mv src dst` with `dst`
an existing directory moves `src` **inside** it, giving you
`work/<owner>/current/<slug>/plan.md` rather than `work/<owner>/current/plan.md`. Nothing errors.
The session brief then reports no active task, because it looks for `plan.md` one level up, and the
task reads as lost. `rmdir` only succeeds on an empty directory, so it cannot destroy a live task
even if the guard above is somehow skipped.

Confirm the shape afterwards rather than assuming it:

```bash
ls "$WORK_CURRENT"                          # expect plan.md and handoff.md, not a directory
```

Then read the handoff's `**Blocked on:**` line **first**. It names the event that has to have
happened for this task to be workable. If it has not happened, say so and stop, rather than
starting work that will park again in ten minutes.

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
- **The SHA is not in this repo's history at all**, or the working-docs clone has commits `origin`
  does not — **stop and report.** Do not merge, do not reset, do not "reconcile" anything. Two
  machines have written to the same live plan, and `plan.md` is rewritten in place, so no merge
  strategy can recover the intent. Show the user both sides and let them choose.

A missing stamp is not a divergence; it means the last save predates this convention. Say so once
and carry on.

## 1. Read, in this order

1. `.claude/$WORK_CURRENT/handoff.md` — the instruction from the last session. This is the primary input.
2. `.claude/$WORK_CURRENT/plan.md` — the objective and task status.
3. `.claude/work/decisions.md` — read at least the most recent entries. **Do not re-litigate anything
   recorded here.** If you think a past decision is wrong, say so explicitly rather than quietly
   doing something else.
4. `.claude/work/hotfixes.md` — temporary code you might otherwise mistake for a bug, or delete.
5. `.claude/work/traps.md` — the workspace gotchas. Cheap to read, and each one is there because it
   already cost someone a session.
6. `.claude/work/issues.md` — only to notice what's already logged, so you don't re-report it.
7. `.claude/work/collab.md`, if it exists — the repo is shared. Read the **Open** items: each one
   is a decision on one side that overrides work on the other, and acting against an open item is
   how someone's work gets silently overwritten.

`$WORK_CURRENT/plan_superseded.md` is reference only. Don't read it on load, and never action anything in
it — it holds the original wording of tasks that are already done.

If `$WORK_CURRENT/` is empty or has no `plan.md`, there is **no active task**. Say so and point at
`/start`. Do not invent one.

**If the repo is shared and this session follows a merge**, read the *tail* of the persistent docs
before trusting them: they merge with `merge=union`, which never reports a conflict, so two people
editing the same entry yields both versions interleaved. A doubled or self-contradicting entry is
a merge artefact to fix, not a decision to follow.

## 2. Verify the handoff against reality

The handoff may be days old. Treat it as a claim to check, not a fact. Confirm before relying on it:

- **Branches.** `git branch --show-current` for every repo the work spans — see `CLAUDE.md`'s repo
  layout. The handoff's manifest may name a branch you are no longer on.
- **Working tree.** `git status --short` per repo. Files may have been committed, reverted, or
  further edited since. Conflicts recorded as unresolved may now be resolved — or vice versa.
- **Specific claims.** If the handoff says a file is in a particular state ("unresolved conflict",
  "stub", "not yet written"), open it and confirm. Cheap, and it's the class of thing that silently
  goes stale.
- **`[~]` items in the plan.** These are done-but-unverified. Check whether the verification named
  in `Verify by:` has since happened. Never promote `[~]` to `[x]` yourself on inference — only on
  evidence, or on the user telling you they ran it.

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

Then **wait for the user**. `/load` orients; it does not begin work. If the next action is obvious
and small, still confirm before starting — the user may have switched priorities since the handoff
was written, which is exactly the information the docs can't have.

## Constraints

- Read-only. `/load` changes no files, including the docs — if they're wrong, report it and let
  `/save` or the user fix it.
- Don't commit, push, or start edits.
- Respect `CLAUDE.md`'s rule on who runs the environment. If verifying something requires a run you
  are not allowed to make, say what you need and ask the user to run it.
