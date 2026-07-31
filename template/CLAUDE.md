# <PROJECT> — working rules

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 1. WHO RUNS THE ENVIRONMENT

     The most valuable rule in this file, and the one most projects omit until an agent breaks
     something. State plainly which commands the agent may run and which it must hand back to you.
     Be specific: name the binaries, not the category.

     Delete this whole block if the agent may run everything.

     Shape to copy:

         ## <Name> runs the environment. You do not.

         **Never start the stack, the build, or the test suite yourself.** No `docker compose up`,
         no `make deploy`, no `./run.sh`, no migrations against any database.

         **Instead:** make the code/config/doc changes, then hand off the **exact command** to run
         and the **log markers that indicate success or failure**. Then stop and wait.

         **What you may still do:**
         - Read already-generated output — logs, reports, result directories.
         - Read-only local analysis that touches nothing shared.
         - Any git, grep, or file inspection.

         The line is: **inspecting artifacts is fine; starting the stack is not.**

     Two things make that work, and are worth copying:
       - it lists the actual command names, so there is nothing to interpret;
       - it says what the agent should do INSTEAD, so the rule doesn't dead-end.

     If you want this enforced rather than merely written down, settings.json ships a commented-out
     PreToolUse hook that blocks matching Bash commands. Prose alone gets violated.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->


<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 2. REPO LAYOUT

     Delete this section entirely if the project is a single repo on one branch.

     Fill it in if work spans submodules, sibling checkouts, or vendored repos — the agent cannot
     otherwise know that `git status` at the root tells it nothing about most of the work.

         Work spans three repos, each on its own branch — always read the branch, never assume:

         | Path | Repo | Branch (as of <YYYY-MM-DD>) |
         |---|---|---|
         | `.`           | app     | `feature-x` |
         | `vendor/lib`  | lib     | `feature-x` |

         Everything else under `vendor/` is shared — **do not modify** without saying so first.

     Date the branch column. Branches move; an undated table quietly becomes a lie.

     Then list the 3–5 paths that matter most, so an agent doesn't have to search for them:

         Key paths:
         - Core logic: `path/to/thing.py`
         - Entrypoint: `path/to/run.py`
     ══════════════════════════════════════════════════════════════════════════════════════════ -->


## Working docs

Session state lives in `.claude/`:

**Task-scoped** — `.claude/work/current/`, archived by `/done` when the task ends:

| File | |
|---|---|
| `work/current/plan.md` | objective + tasks. `[ ]` pending · `[x]` done **and verified** · `[~]` done, NOT verified. **A task list, not a record** — see the size rules below |
| `work/current/plan_superseded.md` | original wording of tasks now done. Reference only, never actionable |
| `work/current/history.md` | append-only session log for this task |
| `work/current/handoff.md` | prompt for the next session — **read this first** |

**Persistent** — these describe the *code*, not the work, so they outlive the task:

| File | |
|---|---|
| `decisions.md` | append-only: what was chosen and why |
| `issues.md` | staged for the tracker, for other people |
| `hotfixes.md` | temporary code in the tree, each with a `Remove when:` and an `Owner:` |
| `traps.md` | permanent gotchas about this workspace — the things that bite every session |
| `collab.md` | running agenda between the people who share this repo — anything on one side that conflicts with or overrides the other's work. Mark **Agreed** with a date; never delete. *Delete this row if you work alone* |

Finished tasks land in `.claude/work/archive/<YYYY-MM>_<slug>/` — **tracked**, so a finished task's
record reaches everyone. Only `work/current/` is per-person.

### Keep `plan.md` small — it is a task list, not a record

Left alone it grows without bound. In the project this template came from it reached **1432 lines**
and had to be halved by hand. Evidence, rationale and superseded wording had all piled up in it, and
each of those already has a file that owns it: what happened → `work/current/history.md` · why →
`decisions.md` · original wording of a finished task → `work/current/plan_superseded.md` · temporary code
→ `hotfixes.md` · someone else's work → `issues.md`.

- **Completed item: ≤ 3 lines**, compressed **when you tick it** — what was done, the one piece of
  evidence that verifies it, and where the detail lives. Never paste the evidence in.
- **Open item: ≤ 20 lines** — what to do, the verify-by, and any constraint that causes harm if
  forgotten. Longer reasoning goes in `decisions.md`, and the plan links to it.
- **Soft cap ~600 lines.** Over it, compress the biggest completed items before appending new ones.
- **Amalgamate** duplicate items rather than keeping both.

### Keep one task per task

`/done` exists and should actually fire. A task whose objective needs six lettered sections is a
*program*, not a task — split it, and let each section close on its own gate. The symptom of getting
this wrong is an empty `archive/` next to a plan and history that no longer fit in context, so every
session pays to re-read them before doing any work.

## More than one person uses this `.claude/`

<!-- DELETE THIS WHOLE SECTION IF YOU WORK ALONE. Keep it the moment a second person clones the
     repo and starts running /start and /save on their own machine — every rule below is a bug
     that has to be fixed anyway once that happens, and three of them are silent. -->

`.claude/` is checked into the repo and used by several people on their own machines. The
machinery, the skills and the persistent docs are shared; `work/current/` and
`settings.local.json` are not. Four rules follow, and all four are non-obvious.

**1. The persistent docs merge by union — so stamp every entry with an author.**
`decisions.md`, `traps.md`, `hotfixes.md`, `issues.md` and `collab.md` are append-only, so
everyone writes to the tail of the same file — the most conflict-prone shape in git. Put this in
the repo root `.gitattributes`:

```gitattributes
.claude/work/*.md merge=union
```

Both sides' lines then survive with no conflict markers. The catch is that union merge **never
conflicts**. Measured on two branches each appending one entry:

- Entries with **distinct** text merge **correctly** — both survive whole and in order. The only
  damage is that the blank line between them is eaten, being common to both sides. Cosmetic.
- Lines that are **byte-identical** on both sides are **deduplicated**, and the two entries
  interleave into one block that reads as a single coherent entry and is not. Silent, and the
  reason boilerplate-only entries are dangerous.

So:

- Every entry's heading or stamp carries `— <author>`: `## <YYYY-MM-DD> — <name> — <title>`. Keep
  the body distinctive too — a real `**Affects:** path` line is what stops two entries collapsing
  into each other.
- After a merge that touched these files, **read the tail**: `git diff HEAD~1 -- .claude/work/`.
  The merge won't have told you.
- Editing or deleting *someone else's* entry is a `collab.md` item, not a silent rewrite.

**2. Hook and settings changes go through a PR.** `settings.json` and everything in `hooks/` is
executable code that runs on everyone else's machine at session start, on their next pull, without
them reading the diff. This is the one part of `.claude/` where "it's just docs" is false.

**3. `/setup` runs once per project, ever — never on a clone.** It rewrites `CLAUDE.md` from the
template's FILL IN blocks and would destroy this file. If you have just cloned, `.claude/` is
already set up: start with `/load`. Personal settings go in `settings.local.json`, which is
gitignored and exists exactly for that.

**4. Verification is per-machine.** `[x]` means *you* saw it verified, on your machine. Never
promote someone else's `[~]` to `[x]` because their notes read as finished — re-run the
`Verify by:` or leave it alone.

## Workflow

**Start the task**

1. New task
2. `/start` — agree the objective, write `work/current/plan.md` **before any code**
3. Work

**Then loop, once per session** ⟳

4. `/save` — update every doc, write the next-session prompt · *last thing before you stop*
5. `/load` — read the handoff, check it against the repo, report · *first thing when you return*
6. Work
7. Not finished? → back to **4**

**Finish the task**

8. `/done <slug>` — settle every loose end, then archive `work/current/` → `archive/<YYYY-MM>_<slug>/`

Docs can go stale between sessions. Where the docs and the repo disagree, **the repo wins** —
report the discrepancy rather than following the stale version.


<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 3. FILING ISSUES

     Delete if the agent never files issues on your behalf.

     Fill in if it does. Filing notifies real people and cannot be cleanly undone, so this section
     is mostly about consent and verification, not mechanics. Cover:

       - **Tracker + tool.** GitHub/`gh`, GitLab/`glab`, Jira/… and any flag the tool needs to
         resolve the right host. Note who owns the credential, and that the agent must never read
         or print the token — only invoke the tool.

       - **The confirmation rule.** Recommended, and the reason this section exists:

             **Confirm before every single file action.** Print the exact title, body, assignee,
             labels and target project, then wait for an OK. One confirmation per issue — never a
             batch, never opportunistically mid-task.

       - **Target project**, and whether it varies by component. If it does not, say so once and
         loudly — per-component mapping tables rot.

       - **Labels.** Check whether your tracker CREATES an unknown label as a side effect of using
         it. Several do. If so, the safe default is to pass none and let the owner triage.

       - **Verify after filing; don't trust the exit code.** Re-read the issue and confirm the
         assignee, the label set, and that any collapsed or formatted blocks survived. A filed issue
         with a mangled body is worse than an unfiled one.

       - **The sync obligation.** A staged issue can be rewritten freely; a filed one cannot. Once
         filed, the tracker is the source of truth — changes go to the tracker in the same session,
         and `issues.md` must not become a private fork of it.

     Record any tool quirk you hit here the moment you hit it. These cost an hour each, every time,
     and they are exactly what a cold session cannot rediscover.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->


<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 4. FILES OUTSIDE YOUR SCOPE

     Delete if you own the whole tree.

     Fill in if the working tree carries deliberate edits to other people's components, or if some
     directories are off-limits. State which paths, and point at `hotfixes.md` for the per-file
     disposition — because the rules are usually NOT uniform. In the project this came from, one
     owner's file had to be committed and another had to never be, and only the hotfix entry knew
     which was which.

         **Read `hotfixes.md` before editing, staging, or reverting anything under `<paths>`.**
         Every such edit has an entry there with its commit disposition, its canary, and its
         `Remove when:`.

     Also worth stating here: any file with a non-obvious recovery path. If reducing a config means
     commenting out rather than deleting, or if `git show HEAD:<file>` is NOT a valid restore
     because the committed revision predates working-tree tuning, say so — an agent will otherwise
     reach for git and lose work that was never committed.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->


## Conventions

- **Never mark work `[x]` that you have not seen verified.** If it only compiled, or only ran
  somewhere that doesn't count, it is `[~]`. Work that looks done and isn't is the most expensive
  failure mode this system has.
- **Every task needs a `Verify by:`** — the command, the log line, the artifact to inspect. A task
  with no verification method is how `[~]` items become false `[x]`s later.
- Absolute dates only, never "today" or "last session".
- Reference code as `path:line`.
- Don't commit or push unless asked.
- Flag temporary work as temporary and add it to `hotfixes.md`.
- Date rules when you change them, and supersede rather than overwrite: strike the old line through
  and add the new one with its date and reason. The reversal trail is worth more than a tidy file.

<!-- FILL IN — house style: language or formatting rules an agent would otherwise get wrong.
     e.g. "No column alignment — don't pad spaces to line up `=` or arguments."
          "Screenshots: when asked to look at an image without a path, read the most recent file
           in <your screenshot directory>." -->

## Do not use the auto-memory store for this project

**Write project state into the file that owns that lifetime**, not into a memory file:
temporary code → `hotfixes.md` · someone else's work → `issues.md` · why → `decisions.md` ·
what happened → `work/current/history.md` · what's next → `work/current/plan.md` · workspace gotchas →
`traps.md` · how we work → this file.

The reason is not that memory is useless — it is that a second, auto-loading store of the same facts
drifts out of sync with the files, and a stale memory that presents itself as current is worse than
no memory at all. That is what happened in the project this template came from: two entries had gone
wrong while still auto-loading as though true, and the store was deleted.

<!-- Delete this section if you would rather use the memory store. If you do keep memory, at least
     pick ONE home per fact — the failure is duplication, not memory itself. -->
