---
name: start
description: Open a new task — agree the objective and write the task list into $WORK_CURRENT/plan.md before any code is written. Use when starting a new piece of work, when the user asks to plan something out, or when the current plan no longer matches what is actually being built.
model: sonnet
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
- Temporary code the plan may have to work around or clean up: `work/hotfixes.md`, or
  `.claude/bin/task.sh temporary` where `TRACKER_FIRST="yes"` and `TEMPORARY (` markers in the code
  replaced the file.
- `work/traps.md`: gotchas that invalidate a planned approach before you start.
- `work/collab.md`, if it exists — don't plan work another owner's open item claims or contests.

## 2. Agree the objective before listing tasks

State in 1–3 sentences what "done" means and what is explicitly **out of scope**; ambiguity that
would change the task list gets asked about now. **Size it honestly:** an objective needing more
than one lettered section, or more work than a few sessions, is a **program, not a task** — split
it and plan the first piece only, or it never passes `/done`'s gate (`CLAUDE.md`, one task per task).

```bash
.claude/bin/task.sh start "<objective, one line>"
```

Its **first lines are the parked tasks**, each with its blocker. Read them before planning: if one
now looks unblocked, say so and offer `/load <slug>`, which is probably the better session, and let
the user choose. Then it creates `$WORK_CURRENT`, seeds `history.md`, and prints the path last. **It
refuses when `$WORK_CURRENT` is not empty**, listing what is there: an unfinished task. Stop, report
it, and ask whether to continue that one, `/park <slug>` it, or close it with `/done`.

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
- <thing>: why, and where it went (a tracker issue, `issues.md` on a file-based install, a later
  plan, dropped). Nothing stays here without a home.
```

- One task = one reviewable change that **leaves the tree compiling and is independently pushable**.
  Fold a step that exists only to be undone by the next one into the step that completes it; where
  nothing can be split that way, a signature change reaching every caller at once, the plan says so
  and the chunk stays whole rather than pretending to a granularity the code will not allow.
- **If any task touches something `CLAUDE.md`'s review routing sends through a PR, task one is
  creating the branch**, named per `BRANCH_PATTERN` in `project.conf` (`<owner>_<slug>` by default),
  with `**Verify by:** git rev-parse --abbrev-ref HEAD`. Routing governs *committing*, which is
  several steps later, so a plan can satisfy every rule here and still put the first edit on the
  default branch. The branch is a task or it is nowhere.
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
