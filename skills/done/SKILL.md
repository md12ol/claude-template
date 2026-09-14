---
name: done
description: Close out the finished task: run a final save, settle every loose end, then archive $WORK_CURRENT to work/archive/<YYYY-MM>_<slug>/ and leave a clean desk. Use when the user says a task is done, finished or wrapped up, or wants to start a new task.
model: sonnet
---

# Done

`/save` checkpoints work *within* a task; `/done` ends one and clears the desk for the next, and
**it should fire regularly.** An empty `archive/` beside a long-running `$WORK_CURRENT/` means
tasks are being merged into a program that never closes, and every later session pays to re-read a
plan and history that no longer fit in context. If the objective has grown past what this gate can
pass, close the part that *is* finished and `/start` the rest. `CLAUDE.md`'s two tables say which
files move.

## 0. Where work lives

```bash
eval "$(.claude/bin/task.sh paths)" && .claude/bin/task.sh pull
```

Both paths are inside the `.claude/` repository, never the branch you are coding on. On a shared
install an unrecognised git email stops here; ask whose it is, never guess.

## 1. Read the argument for intent

Normally the argument is the **archive slug**, what follows `<YYYY-MM>_`. `/done api-migration` →
`work/archive/2026-07_api-migration/`. Lowercase it, spaces and underscores to hyphens, strip
anything outside `[a-z0-9-]`. Unless it clearly is not a slug:

- Carries its own year-month (`2026-07_api`, `july api work`) → the full directory name or a date.
  Don't double-prefix.
- A path, or an existing archive directory → they mean *that* directory; ask before writing into it.
- A sentence or directive (`just the teardown work`, `don't archive yet, only save`) → scope, not a
  name: follow it, and derive the slug from the plan's objective.
- Empty → derive it from the `# Plan:` line, and **show it for confirmation** before archiving.

In doubt, say which slug you are about to use and why, then proceed.

### A parked slug is accepted, and unparked here

If `<slug>` is in `$WORK_PARKED`, do the swap `/load` does first: park a live task if one is in the
way, then

```bash
.claude/bin/task.sh unpark <slug>
.claude/bin/task.sh check-stamp
```

and **stop on divergence exactly as `/load` would** (that skill's §2 has the three shapes): never
archive a task whose parked copy and `origin` disagree. Otherwise continue into step 2. The order is
the safety property the older refusal protected: the final save still runs live, in the session
closing the task, rather than against notes written weeks ago.

## 2. Save, then check the task is actually finished

**Run `/save` in full**, no shortcuts: it is the last chance to capture rationale from the live
conversation, and everything below assumes current docs. Then read `$WORK_CURRENT/plan.md`.
Any `[ ]` pending or `[~]` unverified items, or unanswered open questions? **Stop and list them.**
Ask whether each is done, abandoned, or moving to the next task. Never archive over unfinished work,
`[~]` especially, since that is work which only *looks* done.

## 3. Sweep the persistent files before they carry forward

- **Temporary code**: `hotfixes.md`, or `.claude/bin/task.sh temporary` where
  `TRACKER_FIRST="yes"` and the `TEMPORARY (` markers replaced the file. Two passes each. **Is the
  code still there?** Read the file; drop what is gone. **Is the removal condition met?** Check what
  you actually can, stamp every survivor `**Last checked:** <YYYY-MM-DD>`, and where you cannot
  verify write `Last checked: <date>, could not verify, needs <who/what>` rather than implying you
  checked. **Never mark a condition met on inference.** Then list what now looks removable, and what
  has been unverifiable for more than about two task cycles.
- **Findings**: `issues.md` entries still `Filed: not yet`, or on a tracker-first install every
  finding this task reported and never filed, from `history.md` and this session. File them now;
  once the task is archived nobody looks again.
- `traps.md`: drop any entry no longer true (the tool was fixed, the path changed).
- `collab.md`, if it exists: mark what this task settled, flag any Open item its outcome overtook,
  and never delete an item.
- `decisions.md`: append a `## Task complete: <slug>, <YYYY-MM-DD>` marker, so later entries are
  attributable to the right task.

## 4. GATE: do not archive until everything outstanding is dispositioned

A hard stop, and the last moment anyone looks at this task's loose ends. Collect them as one
numbered list: unfiled findings; temporary code whose removal condition now looks met, and anything
added during this task; `[ ]` and `[~]` items; unanswered open questions. **The gate is
acknowledgment, not resolution.** Every item needs a disposition, and these are all valid answers:

- *File it now*: do it, and record the URL or issue number with the entry.
- *Carry forward*: it stays for the next task; say so in the archive README.
- *Drop it*: remove the entry, noting why in `decisions.md`. *Already handled*: verify, then remove.

Temporary code blocked on someone else's work is **carried forward**, not a blocker. **Never
disposition an item on the user's behalf**, and no answer to the list means stop there: a `/done`
that saved but did not archive is recoverable; an archive that swallowed unresolved work is not.

## 5. Archive, write the README, commit

```bash
.claude/bin/task.sh archive <slug>
```

It normalises the slug, creates `work/archive/<YYYY-MM>_<slug>/` from today's year-month, moves
every file out of `$WORK_CURRENT` into it, and prints the path. It refuses when that directory
already exists (suggesting `-2`) and when `$WORK_CURRENT` has no `plan.md`. Then write `README.md`
in it: the objective, the dates spanned (first and last session in `history.md`), the outcome in
2–3 sentences, and anything left behind that outlived the task. Then commit:

```bash
.claude/bin/task.sh commit "done: <slug>"
```

`commit` stages **everything changed in the docs repository**, so the archive move, the
`decisions.md` marker, the trap edits and the `Last checked:` stamps land in one commit; it holds no
code, so nothing of the project can ride along. It pushes too: an archive that never reaches
`origin` is invisible on the other machine. **On a rejected push, do not force**, report and stop.
`$WORK_CURRENT/` is left empty, which is how `/start` knows there is no task.

## 6. Delete the task's branch, once it is merged

```bash
.claude/bin/task.sh branch-done <branch>
```

In the **code** repo: it refuses while that branch is checked out, and deletes it locally then
remotely once it is merged into the default branch. **It exits 1 and deletes nothing when the branch
is not merged**, saying the PR is still open. Report whichever happened and never work around a
refusal: deleting an open PR's branch closes it unmerged. A remote copy already gone is the normal
case, and it says so rather than failing.

## 7. Report

What was archived and where, the disposition of every gate item, what carried forward, whether the
branch was deleted or is waiting on its PR, and that the next step is `/start`.

## Constraints

- If the argument said to save but not archive, do step 2 only and stop.
- Nothing here touches the project's repository except step 6's branch deletion; source code still
  needs its own instruction.
