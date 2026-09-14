---
name: done
description: Close out the finished task — run a final save, settle every loose end, then archive $WORK_CURRENT to work/archive/<YYYY-MM>_<slug>/ and leave a clean desk. Use when the user says a task is done, finished or wrapped up, or wants to start a new task.
---

# Done

`/save` checkpoints work *within* a task; `/done` ends one and clears the desk for the next.

**This should fire regularly.** An empty `archive/` beside a long-running `$WORK_CURRENT/` means
tasks are being merged into a program that never closes, and every later session pays to re-read a
plan and history that no longer fit in context. If the objective has grown past what this gate can
pass, close the part that *is* finished and `/start` the rest. Which files move and which stay is
`CLAUDE.md`'s two tables: the task-scoped four go, the persistent docs describe the code and stay.

## 0. Where work lives

```bash
eval "$(.claude/bin/task.sh paths)" && .claude/bin/task.sh pull
```

Both paths are inside the `.claude/` repository, never the branch you are coding on. On a shared
install an unrecognised git email stops here — ask whose it is, never guess.

## 1. Read the argument for intent

Normally the argument is the **archive slug** — what follows `<YYYY-MM>_`. `/done api-migration` →
`work/archive/2026-07_api-migration/`. Lowercase it, spaces and underscores to hyphens, strip
anything outside `[a-z0-9-]`. Unless it clearly is not a slug:

- Carries its own year-month (`2026-07_api`, `july api work`) → they are giving the full directory
  name or a date. Don't double-prefix.
- A path, or an existing archive directory → they mean *that* directory; ask before writing into it.
- A sentence or directive (`just the teardown work`, `don't archive yet, only save`) → scope, not a
  name. Follow it, and derive the slug from the plan's objective.
- Empty → derive it from the `# Plan —` line, and **show it for confirmation** before archiving.

When in doubt, say which slug you are about to use and why, then proceed.

**A parked slug is refused.** If `<slug>` is in `$WORK_PARKED`, stop and say so: resume it with
`/load <slug>` first, then close it. The final save has to run against the session that actually
finished the work — it sweeps loose threads from *this* context, stamps `hotfixes.md` and writes the
README from what happened. Against a directory nobody has opened, all three are guesswork.

## 2. Save, then check the task is actually finished

**Run `/save` in full** — no shortcuts. It is the last chance to capture rationale from the live
conversation, and everything below assumes the docs are current.

Then read `$WORK_CURRENT/plan.md`. Any `[ ]` pending or `[~]` unverified items, or unanswered open
questions? **Stop and list them.** Ask whether each is done, abandoned, or moving to the next task.
Never archive over unfinished work — `[~]` especially, since that is work that only *looks* done.

## 3. Sweep the persistent files before they carry forward

- `hotfixes.md` — two passes per entry. **Is the code still there?** Read the file; delete entries
  whose hotfix is gone. **Is the `Remove when:` condition met?** Check what you actually can, stamp
  every survivor `**Last checked:** <YYYY-MM-DD>`, and where you cannot verify write
  `Last checked: <date> — could not verify, needs <who/what>` rather than implying you checked.
  **Never mark a condition met on inference.** Then list entries whose condition now looks met, and
  entries unverifiable for more than about two task cycles.
- `issues.md` — list everything still `Filed: not yet`, parked entries included. This is the moment
  to file them; once the task is archived nobody looks again.
- `traps.md` — drop any entry no longer true (the tool was fixed, the path changed).
- `collab.md`, if it exists — mark what this task settled, flag any Open item its outcome overtook,
  and never delete an item.
- `decisions.md` — append a `## Task complete: <slug> — <YYYY-MM-DD>` marker, so later entries are
  attributable to the right task.

## 4. GATE — do not archive until everything outstanding is dispositioned

A hard stop. `/done` is the last moment anyone looks at this task's loose ends. Collect them as one
numbered list for the user: issues still `Filed: not yet`; hotfixes whose `Remove when:` now looks
met, and any added during this task; `[ ]` and `[~]` items; unanswered open questions.

**The gate is acknowledgment, not resolution.** Every item needs an explicit disposition, and all
four of these are valid answers:

- *File it now* — do it, record the URL in `Filed:`.
- *Carry forward* — it stays in the persistent file for the next task. Say so in the archive README.
- *Drop it* — remove the entry, and note why in `decisions.md`.
- *Already handled* — verify, then remove.

A hotfix blocked on someone else's work is **carried forward**, not a blocker. **Never disposition
an item on the user's behalf**, and no response to the list means stop there: a `/done` that saved
but did not archive is recoverable, an archive that swallowed unresolved work is not.

## 5. Archive, write the README, commit

```bash
.claude/bin/task.sh archive <slug>
```

It normalises the slug, creates `work/archive/<YYYY-MM>_<slug>/` from today's year-month, moves
every file out of `$WORK_CURRENT` into it, and prints the path. It refuses when that directory
already exists (suggesting `-2`) and when `$WORK_CURRENT` has no `plan.md`.

Then write `README.md` in the archive directory — the objective, the dates spanned (first and last
session in `history.md`), the outcome in 2–3 sentences, and anything left behind that outlived the
task — and commit:

```bash
.claude/bin/task.sh commit "done: <slug>"
```

That commits and pushes the archive, which is the point: an archive that never reaches `origin` is
invisible on the other machine. **On a rejected push, do not force** — report and stop.

`$WORK_CURRENT/` is now empty and stays that way — `/start` scaffolds the next task, and an empty
directory makes it obvious there isn't one.

## 6. Report

What was archived and where, the disposition of every gate item, which hotfixes and issues carried
forward, and that the next step is `/start`.

## Constraints

- If the argument said to save but not archive, do step 2 only and stop.
- Nothing here touches the project's own repository; source code still needs its own instruction.
