# <PROJECT> — working rules

**The rules for working on this project, loaded automatically at the start of every session.** They
say how work is tracked, which file owns which kind of fact, and what needs asking first. Where this
file and the repository disagree, the repository wins — report it, don't follow the stale one.

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 1. WHO RUNS THE ENVIRONMENT

     Name the binaries the agent must hand back to you, not the category; delete this block if it
     may run everything. Shape to copy:

         ## <Name> runs the environment. You do not.

         **Never start the stack, the build, or the test suite yourself.** No `docker compose up`,
         no `make deploy`, no `./run.sh`, no migrations against any database. **Instead:** make the
         changes, hand off the **exact command** and the **log markers for success or failure**,
         then stop and wait. Reading generated output, git, grep and inspection stay yours.

     It holds because it names real commands and says what to do INSTEAD; wire
     `hooks/block_env_commands.sh` to enforce it, because prose alone gets violated.
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

     Date the branch column; an undated table quietly becomes a lie. Then name the 3–5 paths that
     matter most, so nobody has to search for them.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->

## How this `.claude/` is configured

Two files decide the shape of everything below. **Read them; never guess from what is on disk.**

| | |
|---|---|
| `project.conf` | identity (repo, clone URL, host, tracker) and two switches: `PEOPLE` and `MACHINES` |
| `work/owners.txt` | on a shared install, the only copy of the email-to-directory table |

```bash
eval "$(.claude/bin/task.sh paths)"    # OWNER_DIR WORK_CURRENT WORK_PARKED PEOPLE MACHINES
```

**`PEOPLE`** — `solo` keeps live tasks at `work/current/`; `shared` moves them to
`work/<owner>/current/`, turns on the union merge driver, and makes `work/owners.txt` load-bearing:
an address missing from it stops that person's session dead, deliberately. **`MACHINES`** is a
separate question, true far more often than people expect — `multi` wires `pull_main.sh`, stamps
`Machine:` into `handoff.md` and turns on `/load`'s divergence check, and gates nothing else, the
task directory being tracked, committed and pushed on every install. One person with a laptop and a
desktop is `multi`; so is anyone in a cloud container. **Never hardcode a repo name, a clone URL or
a person's email anywhere else**: every hook, script and skill reads those two files through
`hooks/lib.sh`. `.claude/` is itself a clone of the working-docs repository, gitignored by the
project, so no `work/` path shares a commit with the code it describes.

## Working docs

Session state lives in `.claude/`; paths are written `$WORK_CURRENT` where they depend on the
switches. **Task-scoped**, archived by `/done` or moved to `$WORK_PARKED/<slug>/` by `/park`:

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
| `issues.md` | staged for the tracker, for other people |
| `hotfixes.md` | temporary code in the tree, each with a `Remove when:` and an `Owner:` |
| `traps.md` | permanent gotchas about this workspace — the things that bite every session |
| `deferred.md` | **not yet** — wanted, out of scope for now. Sits between your design's non-goals (*never*) and the tracker (*now*). No dates, no ordering, no priority, or it becomes a second build order |
| `traps_retired.md` | traps whose failure has been fixed, each naming the fix. Retire when the mechanism could return; delete when it is simply gone |
| `pipeline_backlog.md` | small changes to *this working-docs system* that block nobody. A churn list, batched to the next sitting if there is a team |
| `reference/` *(outside `work/`)* | how a dependency or toolchain actually behaves — too long for `traps.md`, wrong shape for `decisions.md` because nothing was decided |
| `collab.md` | running agenda between the people who share this repo: anything on one side that conflicts with or overrides the other's work. *Delete this row if you work alone* |
| `collab_settled.md` | the archive half of `collab.md`. Item numbers run as one sequence across both files. *Delete if you work alone* |

Each opens with the template its entries follow — match it rather than inventing a shape. Finished
tasks land in `work/archive/<YYYY-MM>_<slug>/` and meeting notes in `work/meetings/`, both with **no
owner in the path**: finished work is the project's history, and only *live* tasks are per-owner.

### Keep `plan.md` small — it is a task list, not a record

- **Completed item: ≤ 3 lines**, compressed **when you tick it** — what was done, the one piece of
  evidence that verifies it, and where the detail lives. Never paste the evidence in.
- **Open item: ≤ 20 lines** — what to do, the verify-by, and any constraint that causes harm if
  forgotten. Longer reasoning goes in `decisions.md`, and the plan links to it.
- **Soft cap ~600 lines.** Over it, compress the biggest completed items before appending new ones.
- **Amalgamate** duplicate items rather than keeping both.
- **Everything else has a file that owns it:** what happened → `$WORK_CURRENT/history.md` · why →
  `decisions.md` · superseded wording → `$WORK_CURRENT/plan_superseded.md` · temporary code →
  `hotfixes.md` · someone else's work → `issues.md`.

**And keep one task per task.** `/done` exists and should actually fire; a task whose objective needs
six lettered sections is a *program*, so split it and let each part close on its own gate. The
symptom of getting this wrong is an empty `archive/` beside a plan nobody can afford to re-read.

## More than one person uses this `.claude/`

*Delete this whole section if you work alone.* It applies when `project.conf` says
`PEOPLE="shared"` — several people cloning this working-docs repository onto their own machines.
Four rules, all non-obvious.

**1. Three docs merge by union — so stamp every entry with an author and a time.** `decisions.md`,
`collab.md` and `collab_settled.md` are append-only, so everyone writes to the tail of one file, the
most conflict-prone shape in git. `/setup` copies `gitattributes.multi-writer` to `.gitattributes`
**in this repository**, which gives those three, and nothing else, `merge=union`: both sides' lines
survive with no conflict markers, and nothing ever conflicts — which is the catch. Lines
**byte-identical** on both sides are deduplicated, interleaving two entries into one block that
reads as coherent and is not. **`traps.md`, `issues.md`, `hotfixes.md` and `pipeline_backlog.md` are
deliberately NOT union-merged**: they are churn lists where deleting an entry is normal, and union
cannot express a deletion — a delete that races any edit to the same region is silently discarded
and the entry comes back. Those take git's ordinary 3-way merge, so a concurrent append conflicts
and is resolved by hand. Loud and occasional beats silent and wrong.

### Formatting for union merge

An entry's **first and last lines are what a merge treats as shared context**, so those must be
unique. Four rules, all load-bearing:

1. **A unique heading** with author and time: `## <YYYY-MM-DD> <HH:MM> — <name> — <title>`, or
   `### 7. <the item>` in `collab.md`.
2. **A closing stamp repeating both** — `*#7 · raised <YYYY-MM-DD> <HH:MM> — <name>.*`; the number
   and the `HH:MM` are two independent guards against a byte-identical last line.
3. **Never a bare `---` to close an entry** — headings already delimit them, and a repeated
   horizontal rule is exactly the identical boundary line rule 1 warns about.
4. **No bare structural labels** — `- **Body:** <first sentence>`, never `- **Body:**` alone, and
   append the entry's slug to `- **Added:** <date>`. Keep the body distinctive too.

**Audit after every merge that touches these files;** `.claude/bin/task.sh audit` runs both:

```bash
grep -vE '^\s*$' work/<file>.md | sort | uniq -d   # lines two entries could collapse onto
grep -n '^### [0-9]' work/collab.md                # every item heading, at column 0
```

Then read the tail — `git diff HEAD~1 -- work/` from this repository's root; the merge won't have
told you. Editing or deleting *someone else's* entry is a `collab.md` item, not a silent rewrite.

**2. Hook and settings changes go through a PR.** `settings.json` and everything in `hooks/` and
`bin/` is executable code that runs on everyone else's machine at session start, on their next pull,
without them reading the diff. The one part of `.claude/` where "it's just docs" is false.

**3. `/setup` runs once per PROJECT, not once per clone.** It resolves this file's placeholder
blocks and writes `project.conf`; running it again over a configured file destroys what was agreed
once and relied on since. The first person runs it and commits; **everyone after that clones an
already-configured repository and starts with `/load`.** Personal settings go in
`settings.local.json`, which is gitignored and exists for exactly that.

**4. Verification is per-machine.** `[x]` means *you* saw it verified, on your machine. Never
promote someone else's `[~]` because their notes read as finished — re-run the `Verify by:`.

## Comment style

**Every comment written or edited in this project follows `.claude/comment_style.md`.** It reduces
to one test — *would deleting this make a competent reader, new to this code rather than new to the
field, more likely to misunderstand or break it?* — plus one habit: **prefer removing the comment's
reason to exist** over tightening its wording. Read it before a comment-heavy change.

## Workflow

1. New task → **`/start`**: agree the objective and write `$WORK_CURRENT/plan.md` **before any code**.
2. Work.
3. **`/save`**, last thing before you stop — update every doc, write the next-session prompt, commit
   and push the task directory.
4. **`/load [slug]`**, first thing when you return — read the handoff, check it against the repo,
   report. Then back to 2, until the work is finished.
5. **`/done <slug>`** — settle every loose end, then archive `$WORK_CURRENT` into
   `work/archive/<YYYY-MM>_<slug>/`.

**Blocked, not finished** — **`/park <slug>`** saves, stamps what would unblock it, then sets the
task down in `$WORK_PARKED/<slug>/` so `/start` is free; `/load <slug>` picks it up again, parking
whatever is live to make room. **The `Blocked on:` line must name an event someone else could
recognize as having happened**: "waiting on review" is not one, "PR #482 merging" is. The session
brief prints it on every start until the task returns. **`/add-person`** is for the day someone
joins — it restores the coordination files a solo `/setup` removed, adds them to `work/owners.txt`,
installs the merge driver and moves live tasks under an owner, and is **run before they clone**. A
team that also sits down together can move the meeting loop from `skills-optional/` into `skills/`,
which turns `collab.md` into a dated agenda and back into edits.

Behind all of it: `.claude/bin/task.sh` (the task lifecycle), `.claude/bin/setup_apply.sh`,
`.claude/bin/add_person.sh`, and the cloud pair `.claude/bin/cloud_setup.sh` and
`.claude/bin/cloud_ready.sh`; the hooks are in `.claude/hooks/`. Docs go stale between sessions, and
where they and the repo disagree the repo wins — report it rather than following the stale version.

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 3. FILING ISSUES

     Delete if the agent never files issues for you. Filing notifies real people and cannot be
     cleanly undone, so this is about consent more than mechanics. Cover the tool (GitHub/`gh`,
     GitLab/`glab`, Jira/…, the flag that resolves the right host, who owns the credential, and that
     the agent invokes it but never reads or prints the token), and record its quirks here as you
     hit them, since a cold session cannot rediscover them. Then the rule this section exists for:

             **Confirm before every single file action.** Print the exact title, body, assignee,
             labels and target project, then wait for an OK. One confirmation per issue — never a
             batch, never opportunistically mid-task.

     Plus: the **target project**, and whether it varies by component — if not, say so once and
     loudly, because per-component mapping tables rot; **labels**, which several trackers CREATE as
     a side effect of using an unknown one, so where yours does, pass none and let the owner triage;
     and **verify after filing whatever the exit code said**, because a mangled body is worse than
     an unfiled issue. Thereafter the tracker is the truth and `issues.md` must not fork it.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->

<!-- ══════════════════════════════════════════════════════════════════════════════════════════
     FILL IN — 4. FILES OUTSIDE YOUR SCOPE

     Delete if you own the whole tree; fill it in if the working tree carries deliberate edits to
     other people's components, or some directories are off-limits. Name the paths and point at
     `hotfixes.md`, since the rules are rarely uniform and only the entry knows whether a given file
     must be committed or must never be:

         **Read `hotfixes.md` before editing, staging, or reverting anything under `<paths>`.**
         Every such edit has an entry there with its commit disposition, canary and `Remove when:`.

     Name any file whose recovery is not `git show HEAD:<file>`, or an agent reaches for git and
     loses working-tree tuning that was never committed.
     ══════════════════════════════════════════════════════════════════════════════════════════ -->

## Conventions

- **Never mark work `[x]` that you have not seen verified.** If it only compiled, or only ran
  somewhere that doesn't count, it is `[~]`. Work that looks done and isn't is the most expensive
  failure mode this system has.
- **Every task needs a `Verify by:`** — the command, the log line, the artifact to inspect. A task
  with no verification method is how `[~]` items become false `[x]`s later.
- **Don't commit or push unless asked** — with exactly five exceptions, a closed list: `/setup`
  commits its own configuration; `/save`, `/park` and `/done` commit **and push** the task
  directories they write (`$WORK_CURRENT`, `$WORK_PARKED`, `work/archive/`); and `/add-person`
  commits and pushes the switch to a shared repo, because the new person clones next. All five touch
  **the `.claude/` repository only**, never the project, and anything else needs its own explicit
  instruction every time. They exist because an unpushed handoff or archive fails silently: you find
  out on the other machine, usually a day late.
- Absolute dates only, never "today" or "last session". Reference code as `path:line`.
- Flag temporary work as temporary and add it to `hotfixes.md`.
- Date rules when you change them, and supersede rather than overwrite: strike the old line through
  and add the new one with its date and reason. The reversal trail beats a tidy file.

<!-- FILL IN — house style: language or formatting rules an agent would otherwise get wrong.
     e.g. "No column alignment — don't pad spaces to line up `=` or arguments."
          "Screenshots: when asked to look at an image without a path, read the most recent file
           in <your screenshot directory>." -->

## Do not use the auto-memory store for this project

**Write project state into the file that owns that lifetime**, not into a memory file: temporary
code → `hotfixes.md` · someone else's work → `issues.md` · why → `decisions.md` · what happened →
`$WORK_CURRENT/history.md` · what's next → `$WORK_CURRENT/plan.md` · workspace gotchas → `traps.md` ·
how we work → this file. A second auto-loading store of the same facts drifts out of sync with them,
and a stale memory presenting itself as current is worse than none.

<!-- Delete this section if you would rather use the memory store. If you do keep memory, at least
     pick ONE home per fact — the failure is duplication, not memory itself. -->
