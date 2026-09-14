# <PROJECT> — working rules

**The rules for working on this project, loaded automatically at the start of every session.** It
says how work is tracked, which file owns which kind of fact, and what must never be done without
asking. Where this file and the repository disagree, the repository wins — report it, don't follow
the stale version.

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 1. WHO RUNS THE ENVIRONMENT

     The most valuable rule here, and the one most projects omit until an agent breaks something.
     Name the binaries the agent must hand back to you, not the category. Delete this block if the
     agent may run everything. Shape to copy:

         ## <Name> runs the environment. You do not.

         **Never start the stack, the build, or the test suite yourself.** No `docker compose up`,
         no `make deploy`, no `./run.sh`, no migrations against any database.

         **Instead:** make the code/config/doc changes, then hand off the **exact command** to run
         and the **log markers that indicate success or failure**. Then stop and wait.

         **You may still** read generated output (logs, reports, result directories), run read-only
         local analysis, and use git, grep and file inspection. The line is: **inspecting artifacts
         is fine; starting the stack is not.**

     Two things make that work: it names actual commands, so there is nothing to interpret, and it
     says what to do INSTEAD. To enforce it rather than merely write it down, wire
     `hooks/block_env_commands.sh` — prose alone gets violated.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->


<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 2. REPO LAYOUT

     Delete this if the project is a single repo on one branch. Fill it in if work spans submodules,
     sibling checkouts or vendored repos — the agent cannot otherwise know that `git status` at the
     root tells it nothing about most of the work.

         Work spans three repos, each on its own branch — always read the branch, never assume:

         | Path | Repo | Branch (as of <YYYY-MM-DD>) |
         |---|---|---|
         | `.`           | app     | `feature-x` |
         | `vendor/lib`  | lib     | `feature-x` |

         Everything else under `vendor/` is shared — **do not modify** without saying so first.

     Date the branch column — branches move, and an undated table quietly becomes a lie. Then list
     the 3–5 paths that matter most, so an agent doesn't have to search for them:

         Key paths:
         - Core logic: `path/to/thing.py`
         - Entrypoint: `path/to/run.py`
     ══════════════════════════════════════════════════════════════════════════════════════════ -->


## How this `.claude/` is configured

Two files decide the shape of everything below. **Read them; never guess from what is on disk.**

| | |
|---|---|
| `project.conf` | identity (repo, clone URL, host, tracker) and two switches: `PEOPLE` and `MACHINES` |
| `work/owners.txt` | on a shared install, the only copy of the email-to-directory table |

```bash
. .claude/hooks/lib.sh && load_conf && resolve_owner
echo "$WORK_CURRENT"          # work/current  OR  work/<owner>/current
```

**`PEOPLE`** — `solo` keeps live tasks at `work/current/`. `shared` puts them at
`work/<owner>/current/`, turns on the union merge driver, and makes `work/owners.txt` load-bearing:
an address missing from it stops that person's session dead, deliberately. Writing into someone
else's directory is silent, and surfaces only when they open a directory they didn't expect to have
anything in.

**`MACHINES`** — `multi` turns on `pull_main.sh`, the `Machine:` stamp in `handoff.md`, and
`/load`'s divergence check. **Not the same question as `PEOPLE`.** One person with a laptop and a
desktop is `multi`; so is anyone in a cloud container. The failure it prevents is a stale doc, which
needs two machines, not two people.

**Layout** — `.claude/` is a **clone of this project's working-docs repository**, gitignored by the
project. Every `work/` path is inside *that* repository, never this one, and the two never appear in
the same commit. The accepted cost: a decision entry can land while the code it describes is still
under review.

**Never hardcode any of this anywhere else** — not a repo name, a clone URL or a person's email.
Each belongs in one of the two files above, which every hook, check and skill reads through
`hooks/lib.sh`.

## Working docs

Session state lives in `.claude/`. Paths below are written `$WORK_CURRENT` where they depend on the
switches above.

**Task-scoped** — `$WORK_CURRENT`, archived by `/done` when the task ends, or moved to
`$WORK_PARKED/<slug>/` by `/park` when it is blocked:

| File | |
|---|---|
| `$WORK_CURRENT/plan.md` | objective + tasks. `[ ]` pending · `[x]` done **and verified** · `[~]` done, NOT verified. **A task list, not a record** — see the size rules below |
| `$WORK_CURRENT/plan_superseded.md` | original wording of tasks now done. Reference only, never actionable |
| `$WORK_CURRENT/history.md` | append-only session log for this task |
| `$WORK_CURRENT/handoff.md` | prompt for the next session — **read this first**. On a multi-machine install it carries a `Machine:` stamp and the SHA it was written against, and a `**Blocked on:**` line once parked |

**Persistent** — these describe the *code*, not the work, so they outlive the task:

| File | |
|---|---|
| `decisions.md` | append-only: what was chosen and why |
| `issues.md` | staged for the tracker, for other people |
| `hotfixes.md` | temporary code in the tree, each with a `Remove when:` and an `Owner:` |
| `traps.md` | permanent gotchas about this workspace — the things that bite every session |
| `deferred.md` | **not yet** — wanted, out of scope for now. Sits between your design's non-goals (*never*) and the tracker (*now*). No dates, no ordering, no priority, or it becomes a second build order |
| `traps_retired.md` | traps whose failure has been fixed, each naming the fix. Retire when the mechanism could return; delete when it is simply gone |
| `pipeline_backlog.md` | small changes to *this working-docs system* that block nobody. A churn list — batched to the next sitting if there is a team, applied when convenient if not. Useful either way |
| `reference/` *(outside `work/`)* | how a dependency or toolchain actually behaves — too long for `traps.md`, wrong shape for `decisions.md` because nothing was decided |
| `collab_settled.md` | the archive half of `collab.md`. Item numbers run as one sequence across both files. *Delete if you work alone* |
| `collab.md` | running agenda between the people who share this repo — anything on one side that conflicts with or overrides the other's work. Mark **Agreed** with a date; never delete. *Delete this row if you work alone* |

Finished tasks land in `work/archive/<YYYY-MM>_<slug>/`, with **no owner in the path** — a finished
task is the project's history and belongs to everyone. Only *live* tasks are per-owner. Meeting
notes sit in `work/meetings/` for the same reason.

### Keep `plan.md` small — it is a task list, not a record

Left alone it grows without bound; in the project this template came from it reached 1432 lines and
had to be halved by hand. Evidence, rationale and superseded wording had all piled up in it, and
each already has a file that owns it: what happened → `work/current/history.md` · why →
`decisions.md` · original wording of a finished task → `work/current/plan_superseded.md` ·
temporary code → `hotfixes.md` · someone else's work → `issues.md`.

- **Completed item: ≤ 3 lines**, compressed **when you tick it** — what was done, the one piece of
  evidence that verifies it, and where the detail lives. Never paste the evidence in.
- **Open item: ≤ 20 lines** — what to do, the verify-by, and any constraint that causes harm if
  forgotten. Longer reasoning goes in `decisions.md`, and the plan links to it.
- **Soft cap ~600 lines.** Over it, compress the biggest completed items before appending new ones.
- **Amalgamate** duplicate items rather than keeping both.

### Keep one task per task

`/done` exists and should actually fire. A task whose objective needs six lettered sections is a
*program*, not a task — split it, and let each section close on its own gate. The symptom is an
empty `archive/` beside a plan and history that no longer fit in context, so every session pays to
re-read them before doing any work.

## More than one person uses this `.claude/`

*Delete this whole section if you work alone.* It applies when `project.conf` says
`PEOPLE="shared"` — several people cloning this same working-docs repository onto their own
machines. Four rules, all non-obvious.

**1. Three docs merge by union — so stamp every entry with an author and a time.**
`decisions.md`, `collab.md` and `collab_settled.md` are append-only, so everyone writes to the tail
of the same file, the most conflict-prone shape in git. `/setup` installs the rule by copying
`gitattributes.multi-writer` to `.gitattributes` **in this repository**, not in the project:

```gitattributes
work/decisions.md merge=union
work/collab.md merge=union
work/collab_settled.md merge=union
```

Both sides' lines then survive with no conflict markers. Measured on two branches each appending one
entry: **distinct** text merges correctly, losing only the blank line between the entries; lines
**byte-identical** on both sides are **deduplicated**, interleaving the two entries into one block
that reads as coherent and is not. That silent case is why boilerplate-only entries are dangerous.

**`traps.md`, `issues.md`, `hotfixes.md` and `pipeline_backlog.md` are deliberately NOT union-merged.**
They are **churn lists**, where deleting an entry is normal, and union merge cannot express a
deletion: a delete that races any edit to the same region is silently discarded and the entry comes
back. Those take git's ordinary 3-way merge, so a concurrent append **conflicts** and is resolved by
hand. Loud and occasional beats silent and wrong.

### Formatting for union merge

An entry's **first and last lines are what a merge treats as shared context**, so those must be
unique. Four rules, all load-bearing:

1. **The heading is unique** and carries the author and a time:
   `## <YYYY-MM-DD> <HH:MM> — <name> — <title>`, or `### 7. <the item>` in `collab.md`.
2. **The closing stamp repeats that identity and carries a time** —
   `*#7 · raised <YYYY-MM-DD> <HH:MM> — <name>.*`. Two guards: the item's own number, and the
   `HH:MM`, which makes a byte-identical stamp near-impossible even for two entries by the same
   author on one day. A bare `*Raised <YYYY-MM-DD> — <name>.*` collides the moment someone raises
   two items in a day.
3. **Never close an entry with a bare `---`.** Headings delimit entries; a repeated horizontal rule
   is exactly the identical boundary line rule 1 warns about.
4. **No bare structural labels.** Write `- **Body:** <first sentence>`, not `- **Body:**` alone — a
   label with nothing after it is byte-identical in every entry that uses it. Same for
   `- **Added:** <date>`: append the entry's slug.

Keep the body distinctive too: a real `**Affects:** path` line is what stops two entries collapsing
into each other.

**Audit any of these files** after every merge:

```bash
grep -vE '^\s*$' .claude/work/<file>.md | sort | uniq -d
```

Anything it prints is a line two entries could collapse onto. Fix it before it merges, not after.

- After a merge that touched these files, **read the tail**: `git diff HEAD~1 -- .claude/work/`.
  The merge won't have told you.
- Editing or deleting *someone else's* entry is a `collab.md` item, not a silent rewrite.

**2. Hook and settings changes go through a PR.** `settings.json` and everything in `hooks/` is
executable code that runs on everyone else's machine at session start, on their next pull, without
them reading the diff. This is the one part of `.claude/` where "it's just docs" is false.

**3. `/setup` runs once per PROJECT, not once per clone.** It resolves this file's placeholder
blocks and writes `project.conf`; running it again over a configured file destroys what was agreed
once and relied on since. The first person runs it and commits; **everyone after that clones an
already-configured repository and starts with `/load`.** Personal settings go in
`settings.local.json`, which is gitignored and exists for exactly that. Unsure which case you are
in? A configured file has no placeholder blocks left, and the session brief says so at startup.

**4. Verification is per-machine.** `[x]` means *you* saw it verified, on your machine. Never
promote someone else's `[~]` because their notes read as finished — re-run the `Verify by:` or leave
it alone.

## Comment style

**Every comment written or edited in this project follows `.claude/comment_style.md`.** It reduces
to one test — *would deleting this make a competent reader, new to this code rather than new to the
field, more likely to misunderstand or break it?* — plus one habit: **prefer removing the comment's
reason to exist** over tightening its wording. Read it before a comment-heavy change; otherwise
those two lines are enough.

## Workflow

**Start the task**

1. New task
2. `/start` — agree the objective, write `$WORK_CURRENT/plan.md` **before any code**
3. Work

**Then loop, once per session** ⟳

4. `/save` — update every doc, write the next-session prompt, push the task dir · *last thing before you stop*
5. `/load [slug]` — read the handoff, check it against the repo, report · *first thing when you return*
6. Work
7. Not finished? → back to **4**

**Blocked, not finished**

- `/park <slug>` — save, stamp what would unblock it, then set the task down in
  `$WORK_PARKED/<slug>/` and `/start` something else. `/load <slug>` picks it up again, parking
  whatever is live to make room. **The `Blocked on:` line must name an event someone else could
  recognize as having happened** — "waiting on review" is not one; "PR #482 merging" is. The session
  brief prints it on every start until the task returns.

**Finish the task**

8. `/done <slug>` — settle every loose end, then archive `$WORK_CURRENT` → `archive/<YYYY-MM>_<slug>/`

**Someone joining**

- `/add-person` — restores the coordination files a solo `/setup` removed, adds them to
  `work/owners.txt`, installs the merge driver and moves live tasks under an owner. **Run it before
  they clone**, not after.

Docs can go stale between sessions. Where the docs and the repo disagree, **the repo wins** —
report the discrepancy rather than following the stale version.

<!-- DELETE IF YOU WORK ALONE, or if the team does not sit down together on a schedule.

### Joint meetings — a separate loop

`collab.md` is where questions for a meeting accumulate. Three optional skills turn that pile into
an agenda, a decision, and the edits it implies:

- **`/make-agenda [date]`** classifies every unsettled item and writes `work/meetings/<date>.md`.
  Rerunnable; it never edits `collab.md` beyond marking already-settled items.
- **`/start-meeting [date]`** is a read-only standby. It answers questions about any item from the
  sources, with citations, and **writes nothing** — the `Response` blocks are filled in by hand.
- **`/end-meeting [date]`** reads those responses, compiles the action list, asks its questions in
  one round, gets one confirmation, then executes. An empty `Response` block always stops it.

**The split between deciding and executing is the point.** A meeting that edits files as it goes
leaves half-applied decisions when it overruns, and a half-applied meeting is indistinguishable
from a finished one to the next session.
-->


<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 3. FILING ISSUES

     Delete if the agent never files issues on your behalf. Filing notifies real people and cannot
     be cleanly undone, so this is about consent and verification more than mechanics. Cover:

       - **Tracker + tool** — GitHub/`gh`, GitLab/`glab`, Jira/… and any flag needed to resolve the
         right host. Say who owns the credential, and that the agent invokes the tool but never
         reads or prints the token.

       - **The confirmation rule**, the reason this section exists:

             **Confirm before every single file action.** Print the exact title, body, assignee,
             labels and target project, then wait for an OK. One confirmation per issue — never a
             batch, never opportunistically mid-task.

       - **Target project**, and whether it varies by component. If it does not, say so once and
         loudly — per-component mapping tables rot.

       - **Labels** — several trackers CREATE an unknown label as a side effect of using it. Where
         yours does, pass none and let the owner triage.

       - **Verify after filing; don't trust the exit code.** Re-read the issue: assignee, labels,
         and whether formatted blocks survived. A filed issue with a mangled body is worse than an
         unfiled one.

       - **The sync obligation** — once filed, the tracker is the source of truth. Changes go there
         in the same session, and `issues.md` must not become a private fork of it.

     Record tool quirks the moment you hit them. They cost an hour each, every time, and are exactly
     what a cold session cannot rediscover.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->


<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 4. FILES OUTSIDE YOUR SCOPE

     Delete if you own the whole tree. Fill in if the working tree carries deliberate edits to other
     people's components, or if some directories are off-limits. Name the paths and point at
     `hotfixes.md` for the per-file disposition — the rules are usually NOT uniform, and only the
     hotfix entry knows whether a given file must be committed or must never be.

         **Read `hotfixes.md` before editing, staging, or reverting anything under `<paths>`.**
         Every such edit has an entry there with its commit disposition, its canary, and its
         `Remove when:`.

     Also state any file with a non-obvious recovery path — if `git show HEAD:<file>` is NOT a valid
     restore because the committed revision predates working-tree tuning, say so, or an agent will
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
- **Don't commit or push unless asked** — with exactly four exceptions, a closed list: `/setup`
  commits its own configuration; `/save` and `/park` commit and push the live task directory; and
  `/add-person` commits and pushes the switch to a shared repo, because the new person clones next.
  All four touch **the `.claude/` repository only**, never the project. Anything else needs its own
  explicit instruction, every time, however obvious it looks. The exceptions exist because each
  produces output that is worthless if it never lands: an unpushed handoff fails silently, and you
  find out on the other machine, usually a day late.
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

Not because memory is useless, but because a second auto-loading store of the same facts drifts out
of sync with the files, and a stale memory presenting itself as current is worse than none. In the
project this template came from, two entries had gone wrong while still auto-loading as true, and
the store was deleted.

<!-- Delete this section if you would rather use the memory store. If you do keep memory, at least
     pick ONE home per fact — the failure is duplication, not memory itself. -->
