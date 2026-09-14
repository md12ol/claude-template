# `.claude/` — how work is tracked in this project

Claude Code sessions are stateless. This directory is the memory: what we're building, what was
decided, what's temporarily hacked, and where the last session stopped. Six slash commands
maintain it, plus one for the day a second person joins.

**This directory is its own git repository**, cloned into a project that gitignores it. It is where
this project's *work* is recorded, separately from the code — so it never enters the project's
history, never ships inside a build, and never freezes on whatever branch happens to be checked out.

You don't have to read the rest of this file to use it. The short version:

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

- **`/setup`** runs once, ever. It inspects the repo, asks what it can't infer — above all *which
  commands you run yourself and the agent must not* — and turns the template's `FILL IN` blocks into
  this project's rules. If `CLAUDE.md` has no `FILL IN` blocks left, it's already done.

- **`/start`** agrees the objective and writes `work/current/plan.md` **before any code**. It refuses to
  run if there's an unfinished task in `work/current/`.
- **`/save`** is the important one. It re-reads the session for things that were *discussed but
  never landed* — agreed then diverted, noticed in passing, asked and unanswered — and asks you
  about the ones it can't settle. Then it updates every doc and writes the next-session prompt.
- **`/load`** reads that prompt and **checks it against the repo** before trusting it. Docs go
  stale; where they disagree with the code, the code wins.
- **`/done`** settles every loose end — unfiled issues, hotfixes whose removal condition is now
  met, unverified items — then archives the task.

**`/park <slug>`** sits between `/save` and `/done`: it saves, stamps `handoff.md` with the
concrete event that would unblock the task, and moves the whole task directory aside so `/start` is
free. `/load <slug>` brings it back.

## How this directory is configured

`project.conf` holds this project's identity and two switches; `work/owners.txt` holds the
email-to-directory table on a shared install. **Everything else reads them** — no hook, check or
skill hardcodes a repo name, a clone URL or anyone's email.

| Switch | |
|---|---|
| `PEOPLE=solo\|shared` | whether live tasks sit at `work/current/` or `work/<owner>/current/`, and whether the append-only docs union-merge |
| `MACHINES=single\|multi` | whether `/save` stamps and pushes, and whether `/load` checks for cross-machine divergence |

They are separate questions. One person with two computers is `solo` + `multi`.

If you are not sure which applies, ask before writing anything into a task directory: on a shared
install, writing into the wrong person's directory is silent.

## The files

**Task-scoped** — `work/current/`, archived by `/done`:

| | |
|---|---|
| `work/current/plan.md` | objective + task list. **A task list, not a record** — kept under ~600 lines |
| `work/current/plan_superseded.md` | original wording of finished tasks. Reference only |
| `work/current/history.md` | append-only session log for this task |
| `work/current/handoff.md` | the next-session prompt. Overwritten every save |

**Persistent** — these describe the *code*, so they outlive any one task:

| | |
|---|---|
| `decisions.md` | append-only: what was chosen and why, including reversals |
| `issues.md` | work belonging to other people, staged for the tracker |
| `hotfixes.md` | temporary code in the tree, each with a `Remove when:` and an `Owner:` |
| `traps.md` | permanent workspace gotchas |
| `reference/` | longer-form notes on a dependency or toolchain — outside `work/`, because it is neither task state nor a churn list |
| `collab.md` | cross-owner decisions, when more than one person shares the repo. Delete if you work alone |

`CLAUDE.md` holds the rules themselves and is loaded into every session automatically.

Everything above is tracked, along with `work/archive/`. Only `work/current/` and
`settings.local.json` are per-person — see "More than one person" below.

## The three task states

```
[ ]  pending
[~]  done but NOT verified      ← the one that matters
[x]  done AND verified
```

`[~]` exists because "it compiles" and "it works" are different claims, and conflating them is the
most expensive mistake this system is designed to prevent. Nothing is promoted to `[x]` on
inference — only on evidence, or on you saying you ran it. Every task carries a `Verify by:` line
naming what would prove it.

## Conventions worth knowing

- **Absolute dates only.** "Last session" means nothing to a cold reader three weeks later.
- **Supersede, don't overwrite.** When a rule or decision changes, the old one is struck through and
  the new one dated beside it. The reversal trail is usually worth more than the tidy version.
- **One home per fact.** What happened → `history.md` · why → `decisions.md` · temporary code →
  `hotfixes.md` · someone else's problem → `issues.md` · workspace gotcha → `traps.md`. Duplication
  across files is how half of them go quietly wrong.

## More than one person

If someone else clones this repo and runs `/start` on their own machine, read the "More than one
person uses this `.claude/`" section of `CLAUDE.md` first. The short version:

- **`/setup` runs once per project, ever — never on a clone.** It would overwrite `CLAUDE.md`.
  Start with `/load` instead. Personal settings go in `settings.local.json` (gitignored).
- **Stamp every entry with an author.** The persistent docs merge with `merge=union`, so appends
  never conflict — but union merge never conflicts about *anything*, including two edits to the
  same entry. The stamp is what makes a silent duplicate visible. Read the tail after a merge.
- **Check `Owner:` in `hotfixes.md`.** Someone else's uncommitted hotfix is not in your tree.
- **Hook and `settings.json` changes go through a PR**, both ways. They execute on the other
  person's machine at session start, without them reading the diff.
- **`[x]` is per-machine.** Never promote someone else's `[~]` because their notes read as done.

## Backups

`backup_docs.sh` snapshots this directory to `~/.claude-backups/<project>/<date>/`, fired by hooks
in `settings.json`. **If `.claude/` is tracked by this project's git, you don't need it** — delete
the two hooks. It exists for the case where it isn't, and a same-disk daily copy is a weak
substitute for version control.

---

*Seeded from a working-docs template and free to diverge from it. Nothing here reaches back to
that template, and nothing you change needs to be sent back: this repository is the record of
**this** project's work, and it is yours to reshape.*
