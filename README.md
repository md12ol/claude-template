# `.claude/` — how work is tracked in this project

Claude Code sessions are stateless. This directory is the memory: what is being built, what was
decided, what is temporarily hacked, and where the last session stopped. Six slash commands maintain
it, plus one for the day a second person joins. **It is its own git repository**, cloned into a
project that gitignores it, so the work record never enters the project's history, never ships
inside a build, and never freezes on whatever branch is checked out.

```
/setup   once per project, right after cloning this in — fills in CLAUDE.md and project.conf
/start   at the beginning of a piece of work
/save    last thing before you stop, every session
/load    first thing when you come back
/park    when a task is blocked and you want to work on something else
/done    when the work is finished

/add-person  once, when a second person is about to start on this project
```

Cloned this into a project and not set up yet? Run `/setup`.

## The loop

```
  /setup  ── once per project ──┐
                                ▼
  new task ──▶ /start ──▶ work ──▶ /save ──┐
                            ▲              │
                            └── /load ◀────┘   (once per session)
                                  │
                            finished? ──▶ /done <slug> ──▶ archive/
```

- **`/setup`** runs once, ever: it inspects the repo, asks what it cannot infer — above all *which
  commands you run yourself and the agent must not* — and turns `CLAUDE.md`'s placeholder blocks
  into this project's rules. **`/start`** then agrees the objective and writes the task's `plan.md`
  **before any code**, refusing to run while an unfinished task is still live.
- **`/save`** is the important one. It re-reads the session for what was *discussed but never
  landed* — agreed then diverted, noticed in passing, asked and unanswered — asks about what it
  cannot settle, then updates every doc, writes the next-session prompt, and commits and pushes the
  task directory so the next machine has it. **`/load`** reads that prompt and **checks it against
  the repo** before trusting it: where stale docs disagree with the code, the code wins.
- **`/park <slug>`** sits between `/save` and `/done`: it saves, stamps `handoff.md` with the
  concrete event that would unblock the task, and moves the directory aside so `/start` is free;
  `/load <slug>` brings it back. **`/done`** settles every loose end (unfiled findings, temporary
  code whose removal condition is now met, unverified items), archives the task, pushes that too,
  and deletes the task's branch once it is merged.

Each is a thin skill over `bin/task.sh`, which does the file moves and the git work; the hooks in
`hooks/` handle session start, backups and guard rails. **A skill commits and pushes what it wrote
in `.claude/`, and never code**: an unpushed handoff fails silently, on the other machine, a day
late. Anything in the project's own repository still needs asking, every time.

**Where findings live is a switch.** `TRACKER_FIRST=no`, the default, keeps `issues.md`,
`hotfixes.md` and `deferred.md`. Set it to `yes` and `/setup` removes all three: anything with a
lifecycle becomes a tracker issue, temporary code becomes a `TEMPORARY (<date>)` marker plus the
issue that removes it, and a finding noticed mid-task is reported rather than staged.

## How this directory is configured

`project.conf` holds this project's identity and two switches; `work/owners.txt` holds the
email-to-directory table on a shared install. **Everything else reads them** — nothing hardcodes a
repo name, a clone URL or anyone's email.

| Switch | |
|---|---|
| `PEOPLE=solo\|shared` | whether live tasks sit at `work/current/` or `work/<owner>/current/`, and whether the append-only docs union-merge |
| `MACHINES=single\|multi` | whether `handoff.md` carries a `Machine:` stamp, `pull_main.sh` is wired, and `/load` checks for cross-machine divergence |

Separate questions: one person with two computers is `solo` + `multi`. The task directory is tracked
and pushed either way. Unsure which applies? Ask before writing into a task directory — on a shared
install, writing into the wrong person's is silent.

## Where the rest lives

**`CLAUDE.md` holds the rules themselves** and loads into every session automatically: the file
tables, the three task states (`[ ]` pending, `[~]` done but NOT verified, `[x]` done and verified),
the plan size limits, and the conventions. Read it rather than this file. **More than one person
sharing this repository** has its own section there, worth reading *before* the second person
clones. Changing the hooks is `hooks/README.md`; changing the template this came from is
`TEMPLATE.md`.

*Seeded from a working-docs template and free to diverge from it. Nothing you change needs sending
back: this repository is the record of **this** project's work, and it is yours to reshape.*
