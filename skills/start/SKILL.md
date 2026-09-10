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

**Every `work/` path below is inside the `.claude/` repository**, not the branch this session is
coding on. `.claude/` is a clone of this project's working-docs repo and has one branch of its own.
Pull it first:

```bash
git -C .claude pull --ff-only
```

The main tree's checked-out branch is never switched, stashed or touched.

## 0. Scaffold `$WORK_CURRENT/` if it isn't there

`/done` leaves `$WORK_CURRENT/` empty. `/start` is what makes it usable again, so check and create before
writing anything:

- **`.claude/$WORK_CURRENT/` missing** → create it.
- **`$WORK_CURRENT/history.md` missing or empty** → seed it with a header block, so `/save` has somewhere
  to insert session sections (it appends *after* the header, and an empty file has none):

  ```markdown
  # History — <objective, matching plan.md>

  Append-only session log for this task, newest session first.
  Maintained by `/save`; archived by `/done`.

  ---
  ```

- **`$WORK_CURRENT/handoff.md`** — do not create it. `/save` writes it at the end of the first session.
- **`$WORK_CURRENT/plan_superseded.md`** — do not create it. `/save` creates it the first time a task's
  original wording is displaced.
- **`$WORK_CURRENT/` NOT empty** → there is an unfinished task here. **Stop.** Report what's in it and ask
  whether to continue that task or close it with `/done` first. Never overwrite another task's
  `plan.md` or `history.md`.

## 1. Read first

- The existing `.claude/$WORK_CURRENT/plan.md`, if any. If the objective is unchanged and you are only
  adding work, **append** — don't rewrite finished items or lose their status.
- `.claude/work/decisions.md` — do not re-litigate a decision already recorded there. If the new plan
  contradicts one, that's a decision in its own right: flag it to the user now, and note it so
  `/save` logs the supersession.
- `.claude/work/hotfixes.md` — temporary code the plan may need to work around, or clean up.
- `.claude/work/traps.md` — workspace gotchas that may invalidate a planned approach before you start.
- `.claude/work/collab.md`, if it exists — open cross-owner items. Don't plan work that an open
  item says belongs to, or is contested by, the other owner; settle it there first.

## 2. Agree the objective before listing tasks

State in 1–3 sentences what "done" means for this piece of work, and what is explicitly **out of
scope**. If the request is ambiguous in a way that changes the task list, ask now — that's the whole
point of planning before coding.

**Size the task honestly.** If the objective needs more than one lettered section, or spans work you
would not sit down and finish inside a few sessions, it is a **program, not a task**. Split it and
plan only the first piece. The failure this prevents is a plan that can never pass `/done`'s gate,
grows past the point where it fits in context, and taxes every future session with re-reading it.

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

Use `[ ]` **only** for work that is genuinely still to be done. Never leave a superseded or
reference-only item checkboxed — it moves to `$WORK_CURRENT/plan_superseded.md`. A `[ ]` that can never be
ticked trains everyone to skim past `[ ]`, and that is how a real pending item gets lost.

## 4. Confirm before coding

Show the user the objective and task list and get agreement before making edits. If they change the
shape of the work, update the plan first, then start.

## Constraints

- Don't delete or truncate the existing plan; append and amend.
- Don't record decisions here. Note them for `/save`, which owns `decisions.md`.
