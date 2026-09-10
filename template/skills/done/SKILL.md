---
name: done
description: Close out the finished task — run a final save, then archive .claude/$WORK_CURRENT/ to .claude/work/archive/<YYYY-MM>_<slug>/ and start a clean current/. Use when the user says a task is done, finished, wrapped up, or wants to start a new task.
---

# Done

Close out the current task. `/save` checkpoints work *within* a task; `/done` ends one and clears
the desk for the next.

**This should fire regularly.** An empty `archive/` next to a long-running `$WORK_CURRENT/` means tasks are
being merged into a program that never closes — the plan and history then grow past the point where
they fit in context, and every session pays to re-read them. If the objective has grown to the point
that `/done` can never pass its gate, the right move is to close the part that *is* finished and
`/start` the rest as a new task.

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

## 0.5. Refuse a parked task

`/done <slug>` closes the task in `$WORK_CURRENT`. If the slug names something in `$WORK_PARKED`
instead, **stop and say so**: resume it first with `/load <slug>`, then close it.

```bash
[[ -d "$WORK_PARKED/<slug>" ]] && echo "parked — resume it with /load <slug> before /done"
```

The reason is not tidiness. `/done`'s final save has to run against the session that actually
finished the work: it sweeps loose threads out of *this* session's context, stamps `hotfixes.md`,
and writes the archive README from what happened. Run against a directory nobody has opened, every
one of those is guesswork that reads as fact afterwards.

## The argument

The argument is normally the **archive slug** — the name that follows `<YYYY-MM>_` in the archive
directory. `/done api-migration` → `.claude/work/archive/2026-07_api-migration/`.

Normalize it: lowercase, spaces and underscores to hyphens, strip anything that isn't
`[a-z0-9-]`. `/done "API Migration"` → `api-migration`.

**Unless it clearly isn't a slug.** Read the argument for intent before treating it as a name:

- Contains its own year-month (`2026-07_api`, `july api work`) → the user is giving the full
  directory name or a date. Don't double-prefix.
- A path or an existing archive directory → they mean *that* directory; ask before writing into it.
- A sentence or an instruction (`just the teardown work`, `don't archive yet, only save`) → that's
  scope or a directive, not a name. Follow the instruction, and derive the slug from `plan.md`'s
  objective instead.
- Empty → derive the slug from the `# Plan —` objective line in `$WORK_CURRENT/plan.md`, and **show it to
  the user for confirmation before creating the directory.**

When in doubt, say what slug you're about to use and why, then proceed.

## What moves and what stays

The test is: does the file describe **the work** or **the code**?

| Stays at `.claude/` | Why |
|---|---|
| `CLAUDE.md` | project rules |
| `decisions.md` | most entries constrain the codebase, not just this task |
| `hotfixes.md` | the band-aids are still **in the tree** after the task ends |
| `issues.md` | unfiled work doesn't stop existing |
| `traps.md` | the workspace still behaves that way |
| `collab.md` | coordination outlives any one task; **Agreed** items are never deleted |

| Archives with the task (`$WORK_CURRENT/`) | Why |
|---|---|
| `plan.md` | tasks for one objective, dead once met |
| `plan_superseded.md` | the original wording of those tasks |
| `history.md` | the session log *of this task* |
| `handoff.md` | a prompt to resume a task that's over |

## Steps

**1. Run `/save` first.** Full save, no shortcuts — this is the last chance to capture rationale
from the live conversation. Everything below assumes the docs are current.

**2. Check the task is actually finished.** Read `$WORK_CURRENT/plan.md`:

- Any `[ ]` pending or `[~]` unverified items? **Stop and list them.** Ask whether they are done,
  abandoned, or moving to the next task. Do not archive over unfinished work — `[~]` especially,
  since that's work that only *looks* done.
- Unanswered **Open questions**? Surface them the same way.

**3. Sweep the persistent files** before they carry forward:

- `hotfixes.md` — two passes per entry:
  1. **Is the code still there?** Read the file and confirm. Delete entries whose hotfix is gone.
  2. **Is the `Remove when:` condition met?** Check what you can actually check — has the upstream
     fix landed, has the owner's work shipped, does the symptom still reproduce. Set
     `**Last checked:** <YYYY-MM-DD>` on every surviving entry, and say what you based it on.
     If you cannot verify a condition (it depends on someone else's repo, or on a run you can't
     make), write `Last checked: <date> — could not verify, needs <who/what>` rather than implying
     you checked. **Never mark a condition met on inference.** Removing a load-bearing hotfix on a
     wrong guess breaks everything downstream.

  Then list to the user: entries whose condition now looks met (candidates for deletion), and
  entries not verifiable for more than ~2 task cycles (going stale).
- `issues.md` — anything still `Filed: not yet` gets listed to the user. This is the moment to file
  them; once the task is archived, nobody looks again. Include parked entries: ask whether each is
  still worth keeping or has been overtaken.
- `traps.md` — drop any entry that is no longer true (the tool was fixed, the path changed).
- `collab.md`, if it exists — move anything settled during this task into **Agreed** with its date,
  and flag any Open item this task's outcome has now overtaken. Never delete an item.
- `decisions.md` — append a `## Task complete: <slug> — <YYYY-MM-DD>` marker so later entries are
  attributable to the right task.

**4. GATE — do not archive until everything outstanding is dispositioned.**

This is a hard stop. `/done` is the last moment anyone looks at this task's loose ends; once
`$WORK_CURRENT/` is archived, unfiled issues and undocumented hotfixes are effectively lost.

Collect everything outstanding and present it as a numbered list the user answers:

- Issues still `Filed: not yet` (both tiers).
- Hotfixes whose `Remove when:` condition now looks met, and any added during this task.
- `[ ]` and `[~]` items still in `plan.md`.
- Unanswered open questions.

**The gate is acknowledgment, not resolution.** Every item needs an explicit disposition, and
these are all valid answers:

- *File it now* — do it, record the URL in `Filed:`.
- *Carry forward* — it stays in the persistent file for the next task. Say so in the archive README.
- *Drop it* — remove the entry, and note why in `decisions.md`.
- *Already handled* — verify, then remove.

A hotfix blocked on someone else's work is **carried forward**, not a blocker — otherwise no task
could ever close while an upstream fix is pending.

**Do not proceed to step 5 (archive) until every item has an answer.** If the user doesn't respond to
the list, stop there — a partial `/done` that saved but didn't archive is fine and recoverable; an
archive that swallowed unresolved work is not. Never disposition an item on the user's behalf.

**5. Archive.** Create `.claude/work/archive/<YYYY-MM>_<slug>/` using **today's** year-month. If the
directory exists, do not overwrite — append `-2`, or ask. Then plain `mv` of `$WORK_CURRENT/plan.md`,
`$WORK_CURRENT/plan_superseded.md`, `$WORK_CURRENT/history.md`, `$WORK_CURRENT/handoff.md` into it.
⚠ **`plan_superseded.md` is easy to miss** — it is created lazily by `/save`, so it is absent from
some tasks and present in others. Leaving it behind blocks the next `/start`, which refuses to run
while `$WORK_CURRENT/` is non-empty.

Write a short `README.md` in the archive directory: the objective, dates spanned (first and last
session in `history.md`), the outcome in 2–3 sentences, and any hotfixes or issues left behind that
outlived the task.

**6. Leave `$WORK_CURRENT/` empty.** Do **not** write a stub `plan.md` or seed `history.md` — `/start`
scaffolds the next task, and an empty directory makes it obvious there isn't one.

**7. Report.** Say what was archived and where, the disposition of every item from the gate,
which hotfixes and issues carried forward into the next task, and that the next step is `/start`.

## Constraints

- **`mv`, never delete.** If the archive directory can't be created, stop and say so rather than
  proceeding.
- Do not commit or push.
- If the user's argument said to save but not archive, do step 1 only and stop.
