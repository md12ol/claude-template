---
name: start
description: Open a new task — agree the objective and write the task list into $WORK_CURRENT/plan.md before any code is written. Use when starting a new piece of work, when the user asks to plan something out, or when the current plan no longer matches what is actually being built.
---

# Start

Write `$WORK_CURRENT/plan.md` **before** any code: what we are building, in what order, and how we
will know it worked. `/save` updates statuses later; it does not author the plan.

## 0. Where work lives

```bash
eval "$(.claude/bin/task.sh paths)" && .claude/bin/task.sh pull
```

Both paths are inside the `.claude/` repository, never the branch you are coding on. On a shared
install an unrecognised git email stops here — ask whose it is, never guess.

## 1. Read first

- `$WORK_CURRENT/plan.md`, if one is there — same objective, only adding work → **append**.
- `work/decisions.md` — don't re-litigate these. A plan contradicting one is itself a decision.
- `work/hotfixes.md` and `work/traps.md` — temporary code to work around; gotchas that invalidate
  a planned approach.
- `work/collab.md`, if it exists — don't plan work another owner's open item claims or contests.

## 2. Agree the objective before listing tasks

State in 1–3 sentences what "done" means and what is explicitly **out of scope**; ambiguity that
would change the task list gets asked about now. **Size it honestly:** an objective needing more
than one lettered section, or more work than a few sessions, is a **program, not a task** — split
it and plan the first piece only, or it never passes `/done`'s gate (`CLAUDE.md`, one task per task).

```bash
.claude/bin/task.sh start "<objective, one line>"
```

It creates `$WORK_CURRENT`, seeds `history.md`, and prints the path. **It refuses when
`$WORK_CURRENT` is not empty**, listing what is there: an unfinished task. Stop, report it, and ask
whether to continue that one, `/park <slug>` it, or close it with `/done`.

## 3. Write the plan

```markdown
# Plan — <objective, one line>
_Started <YYYY-MM-DD> · last updated <YYYY-MM-DD>_

## Objective
What done looks like. What is out of scope.

## Tasks
- [ ] <task> — `path/to/file`
      **Verify by:** the command or observation that proves it works.
- [ ] …

## Open questions
- <question> — blocks: <which task>

## Out of scope
- <thing> — why, and where it went (`issues.md`, a later plan, dropped).
```

- One task = one reviewable change that leaves the tree working. If it cannot be verified alone,
  split it — where nothing can be, say so in the plan and keep the chunk whole.
- **Every task needs a `Verify by:`** — the command, the log line, the run to inspect. A task with
  no verification method is how `[~]` items become false `[x]`s later.
- Say where it happens (`path:line`), order by dependency, flag anything needing an environment you
  cannot run locally, and keep to `CLAUDE.md`'s size rules.
- `[ ]` pending · `[x]` done **and verified** · `[~]` done but **not verified**. Use `[ ]` only for
  work still to be done: a `[ ]` that can never be ticked teaches everyone to skim past `[ ]`.

## 4. Confirm before coding

Show the objective and the task list and get agreement before any edit; if the shape of the work
changes, update the plan first. Append and amend an existing plan, never truncate it, and note any
decision for `/save`, which owns `decisions.md`. **Agreeing a plan is never authorization to commit,
push or open a PR** — each needs its own instruction, every time, whatever a plan item says.
