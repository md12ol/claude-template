---
name: start
description: Start a new task — scaffold .claude/$WORK_CURRENT/ and write .claude/$WORK_CURRENT/plan.md — the agreed objective and task list for the current work — BEFORE writing any code. Use when starting a new piece of work, when the user asks to plan something out, or when the current plan no longer matches what is actually being built.
---

# Start

Write `.claude/$WORK_CURRENT/plan.md`: what we're building, in what order, and how we'll know it worked.
This runs **before** code is written. `/save` updates the statuses afterwards; it does not author the
plan.

`/done` tears a task down and leaves `$WORK_CURRENT/` empty. `/start` sets the next one up.

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

## 0.5. Scaffold `$WORK_CURRENT/` if it isn't there

`/done` leaves `$WORK_CURRENT/` empty; `/start` makes it usable again. Check and create before
writing anything:

- **`.claude/$WORK_CURRENT/` missing** → create it.
- **`$WORK_CURRENT/history.md` missing or empty** → seed a header block, so `/save` has somewhere to
  insert session sections (it appends *after* the header, and an empty file has none):

  ```markdown
  # History — <objective, matching plan.md>

  Append-only session log for this task, newest session first.
  Maintained by `/save`; archived by `/done`.

  ---
  ```

- **`$WORK_CURRENT/handoff.md`** — do not create it. `/save` writes it at the end of the first session.
- **`$WORK_CURRENT/plan_superseded.md`** — do not create it. `/save` creates it the first time a task's
  original wording is displaced.
- **`$WORK_CURRENT/` NOT empty** → an unfinished task is here. **Stop.** Report what's in it and ask
  whether to continue it or close it with `/done` first. Never overwrite another task's `plan.md`
  or `history.md`.

## 1. Read first

- The existing `.claude/$WORK_CURRENT/plan.md`, if any. If the objective is unchanged and you are only
  adding work, **append** — don't rewrite finished items or lose their status.
- `.claude/work/decisions.md` — do not re-litigate anything recorded there. A new plan that
  contradicts one is itself a decision: flag it now, and note it so `/save` logs the supersession.
- `.claude/work/hotfixes.md` — temporary code the plan may need to work around, or clean up.
- `.claude/work/traps.md` — workspace gotchas that may invalidate a planned approach before you start.
- `.claude/work/collab.md`, if it exists — open cross-owner items. Don't plan work that an open
  item says belongs to, or is contested by, the other owner; settle it there first.

## 2. Agree the objective before listing tasks

State in 1–3 sentences what "done" means for this piece of work, and what is explicitly **out of
scope**. If the request is ambiguous in a way that changes the task list, ask now — that's the whole
point of planning before coding.

**Size the task honestly.** An objective needing more than one lettered section, or spanning work
you would not finish inside a few sessions, is a **program, not a task**: split it and plan only the
first piece. Otherwise the plan can never pass `/done`'s gate, outgrows the context window, and taxes
every future session with re-reading it.

## 3. Write the plan

```markdown
# Plan — <objective, one line>
_Started <YYYY-MM-DD> · last updated <YYYY-MM-DD>_

## Objective
What done looks like. What's out of scope.

## Tasks
- [ ] <task> — `path/to/file`
      **Verify by:** the command or observation that proves it works.
- [ ] …

## Open questions
- <question> — blocks: <which task>

## Out of scope
- <thing> — why, and where it went (`issues.md`, a later plan, dropped).
```

Rules for tasks:

- One task = one reviewable change. If a task can't be verified on its own, split it.
- **Every task needs a `Verify by:`** — the command, the log line, the run to inspect. A task with
  no verification method is how `[~]` items become false `[x]`s later.
- Say where it happens (`path` or `path:line`) whenever it's known.
- **Keep it short.** An open item is ≤ 20 lines; reasoning goes in `decisions.md` and the plan links
  to it. The plan is a task list, not a record — see `CLAUDE.md`, "Keep `plan.md` small".
- Order by dependency, and call out anything that must run in a special environment versus locally.

Status markers, shared with `/save`:
`[ ]` pending · `[x]` done **and verified** · `[~]` done but **not yet verified**.

Use `[ ]` **only** for work genuinely still to be done. A superseded or reference-only item moves to
`$WORK_CURRENT/plan_superseded.md` — a `[ ]` that can never be ticked trains everyone to skim past
`[ ]`, and that is how a real pending item gets lost.

## 4. Confirm before coding

Show the objective and task list and get agreement before making edits. If the user changes the
shape of the work, update the plan first, then start.

## Constraints

- Don't delete or truncate the existing plan; append and amend.
- Don't record decisions here. Note them for `/save`, which owns `decisions.md`.
