# <PROJECT> — working rules

**The rules for working on this project, loaded automatically at the start of every session.** They
say how work is tracked, which file owns which kind of fact, and what needs asking first. Where this
file and the repository disagree, the repository wins — report it, don't follow the stale one.

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 1. WHO RUNS THE ENVIRONMENT

     Name the binaries the agent hands back to you, not the category; delete this block if it may
     run everything. Shape to copy:

         ## <Name> runs the environment. You do not.

         **Never start the stack, the build, or the test suite yourself.** No `docker compose up`,
         no `make deploy`, no `./run.sh`, no migrations against any database. **Instead:** make the
         changes, hand off the **exact command** and the **log markers for success or failure**,
         then stop and wait. Reading generated output, git, grep and inspection stay yours.

     It holds because it names real commands and says what to do INSTEAD; wire
     `hooks/block_env_commands.sh` to enforce it, since prose alone gets violated.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 2. REPO LAYOUT

     Delete if the project is one repo on one branch; fill it in if work spans submodules, sibling
     checkouts or vendored repos, which `git status` at the root says nothing about:

         Work spans three repos, each on its own branch — read the branch, never assume:

         | Path | Repo | Branch (as of <YYYY-MM-DD>) |
         |---|---|---|
         | `.`           | app  | `feature-x` |
         | `vendor/lib`  | lib  | `feature-x` |

         Everything under `vendor/` is shared — **do not modify** without saying so first.
         Key paths:  core logic `path/to/thing.py` · entrypoint `path/to/run.py`

     Date the branch column: an undated table quietly becomes a lie. Name the few paths that matter.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->

## How this `.claude/` is configured

Two files decide the shape of everything below. **Read them; never guess from what is on disk.**

| | |
|---|---|
| `project.conf` | identity (repo, clone URL, host, tracker) and two switches: `PEOPLE` and `MACHINES` |
| `work/owners.txt` | on a shared install, the only copy of the email-to-directory table |
| the same `project.conf` | five tracker and branch keys: `TRACKER_FIRST` (below), `NEEDS_RULING_LABEL` (the label on a decision that must be ruled before work starts), `KIND_LABELS` (the closed set, one per filed issue; empty means pass none), `LABELS_DERIVED` (`yes` when a workflow derives labels, so an agent passes none), `BRANCH_PATTERN` (how a task's branch is named) |

```bash
eval "$(.claude/bin/task.sh paths)"   # OWNER_DIR, WORK_CURRENT, WORK_PARKED and every key above
```

**`PEOPLE`** — `solo` keeps live tasks at `work/current/`; `shared` moves them to
`work/<owner>/current/`, turns on the union merge driver, and makes `work/owners.txt` load-bearing:
an address missing from it stops that person's session dead, deliberately. **`MACHINES`** is a
separate question, true far more often than people expect — `multi` wires `pull_main.sh`, stamps
`Machine:` into `handoff.md` and turns on `/load`'s divergence check, and gates nothing else, the
task directory being tracked, committed and pushed on every install. A laptop plus a desktop is
`multi`; so is a cloud container. **Never hardcode a repo name, a clone URL or an email anywhere
else**: everything reads these files through `hooks/lib.sh`.

## Working docs

Session state lives in `.claude/`; `$WORK_CURRENT` marks a path that depends on the switches.
**Task-scoped**, archived by `/done` or moved to `$WORK_PARKED/<slug>/` by `/park`:

| File | |
|---|---|
| `$WORK_CURRENT/plan.md` | objective + tasks. `[ ]` pending · `[x]` done **and verified** · `[~]` done, NOT verified. **A task list, not a record** — see the size rules below |
| `$WORK_CURRENT/plan_superseded.md` | original wording of tasks now done. Reference only, never actionable |
| `$WORK_CURRENT/history.md` | append-only session log for this task |
| `$WORK_CURRENT/handoff.md` | prompt for the next session — **read this first**. On a multi-machine install it carries `**Machine:** <host> · saved <YYYY-MM-DD HH:MM> · <sha>`, that `<sha>` being the code repo's short HEAD; once parked it also carries `**Blocked on:**` |

**Persistent** — these describe the *code*, not the work, so they outlive the task:

| File | |
|---|---|
| `decisions.md` | append-only: what was chosen and why |
| `issues.md` | staged for the tracker, for other people. *Removed when `TRACKER_FIRST=yes`* |
| `hotfixes.md` | temporary code in the tree, each with a `Remove when:` and an `Owner:`. *Removed when `TRACKER_FIRST=yes`* |
| `traps.md` | permanent gotchas about this workspace — the things that bite every session |
| `deferred.md` | **not yet** — wanted, out of scope for now. Sits between your design's non-goals (*never*) and the tracker (*now*). No dates, no ordering, no priority, or it becomes a second build order. *Removed when `TRACKER_FIRST=yes`* |
| `issue_style.md` + `templates/` | what a filed issue **says**, and the skeleton to paste. The filing rules themselves are below |
| `traps_retired.md` | traps whose failure has been fixed, each naming the fix. Retire when the mechanism could return; delete when it is simply gone |
| `pipeline_backlog.md` | small changes to *this working-docs system* that block nobody. A churn list, batched to the next sitting if there is a team |
| `reference/` *(outside `work/`)* | how a dependency or toolchain actually behaves — too long for `traps.md`, wrong shape for `decisions.md` because nothing was decided |
| `collab.md` | running agenda between the people who share this repo: anything on one side that conflicts with or overrides the other's work. *Delete this row if you work alone* |
| `collab_settled.md` | the archive half of `collab.md`. Item numbers run as one sequence across both files. *Delete if you work alone* |

Each opens with the template its entries follow — match it rather than inventing a shape. Finished
tasks land in `work/archive/<YYYY-MM>_<slug>/` and meetings in `work/meetings/`, both with **no owner
in the path**: finished work is the project's history, and only *live* tasks are per-owner.

### Tracker-first, when `TRACKER_FIRST=yes`

Anything with a lifecycle (startable, workable, finishable) is a tracker issue and lives nowhere
else, and `/setup` removes the three files marked above. When `TRACKER_FIRST=no` those files stay,
own the same facts, and none of the four consequences below applies:

- **Temporary code is a `TEMPORARY (<date>)` comment at the site** plus the issue whose `Done when:`
  names exactly what comes out. `.claude/bin/task.sh temporary` is the inventory.
- **A finding is reported, not staged.** `/save` and `/done` put it in the brief and `history.md`,
  detailed enough that filing needs no re-derivation, and say it is unfiled. Filing is separate.
- **A filed issue lives in exactly one place.** A pointer is fine ("real fix: issue #230"); a
  restatement is a private fork. The test: if the issue's body changed tomorrow, would this go wrong?
- **A decision owed before work starts is an issue labelled `NEEDS_RULING_LABEL`.** Closing one owes
  the ruling in `decisions.md` with the option not taken, amendments to every doc it binds, and a
  linked follow-up issue. A session asked to add an entry to a removed file stops and says so.

### Keep `plan.md` small — it is a task list, not a record

- **Completed item: ≤ 3 lines**, compressed **when you tick it** — what was done, the one piece of
  evidence verifying it, and where the detail lives. Never paste the evidence in.
- **Open item: ≤ 20 lines** — what to do, the verify-by, and any constraint that causes harm if
  forgotten. Longer reasoning goes in `decisions.md`, linked.
- **Soft cap ~600 lines**; over it, compress the biggest completed items before appending. The
  session brief warns you. **Amalgamate** duplicate items rather than keeping both.
- **Everything else has a file that owns it:** what happened → `$WORK_CURRENT/history.md` · why →
  `decisions.md` · superseded wording → `$WORK_CURRENT/plan_superseded.md` · temporary code →
  `hotfixes.md` · someone else's work → `issues.md`, the last two being a `TEMPORARY (<date>)`
  marker and a tracker issue under `TRACKER_FIRST=yes`.

**And keep one task per task.** `/done` exists and should actually fire; a task whose objective needs
six lettered sections is a *program*, so split it and let each part close on its own gate. The
symptom is an empty `archive/` beside a plan nobody can afford to re-read.

## More than one person uses this `.claude/`

*Delete this whole section if you work alone.* It applies when `project.conf` says `PEOPLE="shared"`,
several people cloning this working-docs repository onto their own machines. Four non-obvious rules.

**1. Three docs merge by union — so stamp every entry with an author and a time.** `/setup` copies
`gitattributes.multi-writer` over `.gitattributes` **in this repository**, giving `decisions.md`,
`collab.md` and `collab_settled.md`, and nothing else, `merge=union`: both sides' appended lines
survive with no conflict markers, and nothing ever conflicts, which is the catch. **Byte-identical**
lines are deduplicated, interleaving two entries into one block that reads as coherent and is not.
**The churn lists are deliberately NOT union-merged** (`traps.md`, `issues.md`, `hotfixes.md`,
`pipeline_backlog.md`): deleting an entry there is normal, union cannot express a deletion, and a
delete racing any edit to the same region is silently discarded. Those take git's ordinary 3-way
merge, where a concurrent append conflicts and is resolved by hand.

### Formatting for union merge

An entry's **first and last lines are what a merge treats as shared context**, so those must be
unique. Four rules, all load-bearing:

1. **A unique heading** with author and time: `## <YYYY-MM-DD> <HH:MM> — <name> — <title>`, or
   `### 7. <the item>` in `collab.md`.
2. **A closing stamp repeating both** — `*#7 · raised <YYYY-MM-DD> <HH:MM> — <name>.*`; the number
   and the `HH:MM` are two independent guards against a byte-identical last line.
3. **Never a bare `---` to close an entry**: headings delimit them already, and a repeated rule is
   exactly the identical boundary line rule 1 warns about.
4. **No bare structural labels** — `- **Body:** <first sentence>`, never `- **Body:**` alone, and
   append the entry's slug to `- **Added:** <date>`. Keep the body distinctive too.

**Audit after every merge that touches these files;** `.claude/bin/task.sh audit` runs both:

```bash
grep -vE '^\s*$' work/<file>.md | sort | uniq -d   # lines two entries could collapse onto
grep -n '^### [0-9]' work/collab.md                # every item heading, at column 0
```

Then read the tail (`git diff HEAD~1 -- work/`); the merge won't have told you. Editing or deleting
*someone else's* entry is a `collab.md` item, not a silent rewrite.

**2. Hook and settings changes go through review**, per the routing rules below: `settings.json`,
`hooks/`, `bin/` and skill frontmatter execute on everyone else's machine at session start, before
anyone reads the diff. The one part of `.claude/` where "it's just docs" is false.

**3. `/setup` runs once per PROJECT, not once per clone.** Running it again over a configured file
destroys what was agreed once and relied on since. The first person runs it and commits; **everyone
after that clones an already-configured repository and starts with `/load`.** Personal settings go
in the gitignored `settings.local.json`, which exists for exactly that.

**4. Verification is per-machine.** `[x]` means *you* saw it verified, here. Never promote someone
else's `[~]` because their notes read as finished; re-run the `Verify by:`.

## Comment style

**Every comment written or edited in this project follows `.claude/comment_style.md`**, which
reduces to one test and one habit. Run `.claude/bin/comment_audit.sh <file>` over what you touched.

## Workflow

1. New task → **`/start`**: agree the objective and write `$WORK_CURRENT/plan.md` **before any code**.
   Where the work routes through a pull request, **task one is creating the branch**, named per
   `BRANCH_PATTERN`, `Verify by: git rev-parse --abbrev-ref HEAD`. **Every task leaves the tree
   compiling and independently pushable**, or the plan says why it cannot be split that way.
2. Work: one task, run its `Verify by:`, **stop and report**. The stop is the review point, not a
   courtesy check-in: a push with no human reading the code is what it prevents.
3. **`/save`**, last thing before you stop — update every doc, write the next-session prompt, commit
   and push.
4. **`/load [slug]`**, first thing when you return — read the handoff, check it against the repo,
   report. With no slug it resolves what to do: the live task, naming any parked one and its blocker;
   the single parked task when the desk is clear; otherwise it asks, or points at `/start`.
5. **`/done <slug>`** — settle every loose end, then archive `$WORK_CURRENT` into
   `work/archive/<YYYY-MM>_<slug>/`. It accepts a **parked** slug and unparks it itself; once the
   branch is merged it deletes both copies (`task.sh branch-done`), reporting while the PR is open.

**Blocked, not finished** — **`/park <slug>`** saves, stamps what would unblock it, then sets the
task down in `$WORK_PARKED/<slug>/` so `/start` is free; `/load <slug>` picks it up again, parking
whatever is live to make room. **The `Blocked on:` line must name an event someone else could
recognize as having happened**: "waiting on review" is not one, "PR #482 merging" is. The session
brief prints it on every start until the task returns. **`/add-person`** is for the day someone
joins: it restores the coordination files a solo `/setup` removed, adds them to `work/owners.txt`,
installs the merge driver, moves live tasks under an owner, and is **run before they clone**.

Behind all of it, in `.claude/bin/`: `task.sh` (the task lifecycle), `setup_apply.sh`,
`add_person.sh`, `comment_audit.sh` and the cloud scripts; the hooks are in `.claude/hooks/`. Docs
go stale between sessions, and where they and the repo disagree the repo wins.

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 3. FILING ISSUES

     Delete if the agent never files issues for you. Filing notifies real people and cannot be
     cleanly undone, so this is about consent more than mechanics. Cover the tool (GitHub/`gh`,
     GitLab/`glab`, Jira/…, the flag resolving the right host, who owns the credential, and that the
     agent invokes it but never reads or prints the token), and record its quirks here as you hit
     them. Then the rule this block exists for:

             **Confirm before every single file action.** Print the exact title, body, assignee,
             labels and target project, then wait for an OK. One confirmation per issue — never a
             batch, never opportunistically mid-task.

     Plus the **target project** and whether it varies by component (if not, say so once and loudly:
     per-component mapping tables rot); and **verify after filing whatever the exit code said**, a
     mangled body being worse than an unfiled issue. Thereafter the tracker is the truth.

     **Labels come from `project.conf`:** exactly one of `KIND_LABELS`, none when that key is empty,
     none a workflow derives when `LABELS_DERIVED` is `yes`, never an invented name (trackers create
     unknown ones silently). What an issue SAYS is `work/issue_style.md` and `work/templates/`.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 4. FILES OUTSIDE YOUR SCOPE

     Delete if you own the whole tree; fill it in if the working tree carries deliberate edits to
     other people's components, or some directories are off-limits. Name the paths and point at
     whatever records each edit's commit disposition: the rules are rarely uniform, and only the
     entry knows whether a given file must be committed or must never be:

         **Read `hotfixes.md` before editing, staging, or reverting anything under `<paths>`.**
         Every such edit has an entry there with its commit disposition, canary and `Remove when:`.
         (Under `TRACKER_FIRST=yes`, that is the `TEMPORARY (<date>)` marker and its issue.)

     Name any file whose recovery is not `git show HEAD:<file>`, or an agent reaches for git and
     loses working-tree tuning that was never committed.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 5. REVIEW ROUTING

     Always fill this in. Route by "does this change what runs", not by which directory it is in,
     and keep the table short enough that nobody re-derives a row. Shape to copy:

         ## Review routing

         | Change | Route |
         |---|---|
         | Anything in the project's own repository | branch + PR, never a direct push |
         | `settings.json`, `hooks/`, `bin/`, skill **frontmatter** | branch + PR, in this repo |
         | `work/*.md`, `CLAUDE.md`, skill **bodies** | direct push to this repo's default branch |
         | `<the design document, if there is one>` | PR, and only once the owners agree |

         Branches are named per `BRANCH_PATTERN` in `project.conf`. **Nobody merges their own pull
         request**, and **an agent never merges unprompted**: it opens one and stops; told to merge,
         it merges, and only what somebody else opened. **Merge a PR touching `work/*.md` locally**,
         never with the host's web button: merge drivers run in your git, not on their servers.

     A solo install keeps the first two rows and the local-merge sentence, which is about the driver
     rather than people. What you write here is what `/start` reads when it decides whether task one
     is creating a branch.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->

## Conventions

- **Never mark work `[x]` you have not seen verified.** If it only compiled, or only ran somewhere
  that doesn't count, it is `[~]`. Work that looks done and isn't is this system's worst failure.
- **Every task needs a `Verify by:`** — the command, the log line, the artifact to inspect. A task
  with no verification method is how `[~]` items become false `[x]`s later.
- **Don't commit or push unless asked**, with one exception: **a skill commits and pushes what it
  wrote in `.claude/`, and never code.** `/setup` commits its configuration (no push); `/save`,
  `/park`, `/load <slug>` and `/done` commit and push; `/add-person` pushes the switch to shared,
  because the new person clones next. `task.sh commit` stages the whole docs repo, which holds no
  code, so a trap written during the task travels with the handoff. Every commit, push and pull
  request in the *project's* repository needs its own instruction each time, and **approving a plan
  is not one**, however plainly a plan step says "open the PR".
- **Never record a count describing the current state of the tree. Record the command that produces
  it**: "`git grep -c TEMPORARY`, run per area", not "nine markers". A maintained number is wrong
  the moment anyone commits, and nothing tells you. The exception is a count **stamped to a date,
  describing something that happened**: evidence, and still true next month unchanged.
- **Ask with the question interface, not with a sentence at the end of an answer.** Put the call in
  front of the reader as a question, with the options and **what each one costs**. Buried in the last
  line of a long answer it fails silently, and the session proceeds on an assumption nobody agreed
  to. The bar is whether two readings lead to materially different work. This does not license asking
  instead of doing: an obvious default is taken, stated, and moved past.
- **A change that falsifies shipped documentation fixes it in the same commit.** A rename or a moved
  line number makes the page wrong in the same breath, and the two belong in one reviewable diff. A
  queue of edits to sweep later is documentation reliably stale between sweeps.
- **No agent co-attribution on commits or pull requests, ever, and never ask**: no trailer, no
  generated-with footer, no session URL. `settings.json` ships an `attribution` block that turns it
  off, and `git log` is what to check before inventing a commit convention.
- **A commit message is three lines at most**: subject, blank line, one body line, and one line
  alone is fine. Never a bulleted body or a per-file breakdown; a change needing that much
  explanation explains itself in the code, in `decisions.md`, or in the pull request body.
- Absolute dates only, never "today" or "last session". Reference code as `path:line`.
- Flag temporary work as temporary and add it to `hotfixes.md`, or under `TRACKER_FIRST=yes` mark it
  `TEMPORARY (<date>)` at the site and file the issue that removes it.
- The task skills carry a `model:` pin in their frontmatter, kept or dropped at `/setup`. That line
  is configuration the harness executes, so it is reviewed like a hook; a skill's body is prose.
- Date rules when you change them, and supersede rather than overwrite: strike the old line through
  and add the new one with its date and reason. The reversal trail beats a tidy file.

<!-- FILL IN — house style: language or formatting rules an agent would otherwise get wrong.
     e.g. "No column alignment — don't pad spaces to line up `=` or arguments."
          "Screenshots: when asked to look at an image without a path, read the most recent file
           in <your screenshot directory>." -->

## Do not use the auto-memory store for this project

**Write project state into the file that owns that lifetime**, not into a memory file: why →
`decisions.md` · what happened → `$WORK_CURRENT/history.md` · what's next → `$WORK_CURRENT/plan.md` ·
gotchas → `traps.md` · how we work → this file · temporary code and other people's work → whichever
mode is on. A second auto-loading store of the same facts drifts, then presents itself as current.

<!-- Delete this section to use the memory store instead; if you do, pick ONE home per fact. -->
