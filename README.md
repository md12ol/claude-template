# `.claude/` — how work is tracked in this project

Claude Code sessions are stateless. This directory is the memory: what we're building, what was
decided, what's temporarily hacked, and where the last session stopped. Six slash commands maintain
it, plus one for the day a second person joins.

**This directory is its own git repository**, cloned into a project that gitignores it — so the work
record never enters the project's history, never ships inside a build, and never freezes on whatever
branch is checked out.

You don't have to read the rest of this file to use it:

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
  this project's rules. No `FILL IN` blocks left in `CLAUDE.md` means it's already done.
- **`/start`** agrees the objective and writes `work/current/plan.md` **before any code**. It refuses
  to run while an unfinished task sits in `work/current/`.
- **`/save`** is the important one. It re-reads the session for what was *discussed but never landed*
  — agreed then diverted, noticed in passing, asked and unanswered — asks you about what it can't
  settle, then updates every doc and writes the next-session prompt.
- **`/load`** reads that prompt and **checks it against the repo** before trusting it. Where stale
  docs disagree with the code, the code wins.
- **`/done`** settles every loose end — unfiled issues, hotfixes whose removal condition is now met,
  unverified items — then archives the task.

**`/park <slug>`** sits between `/save` and `/done`: it saves, stamps `handoff.md` with the
concrete event that would unblock the task, and moves the whole task directory aside so `/start` is
free. `/load <slug>` brings it back.

## How this directory is configured

`project.conf` holds this project's identity and two switches; `work/owners.txt` holds the
email-to-directory table on a shared install. **Everything else reads them** — nothing hardcodes a
repo name, a clone URL or anyone's email.

| Switch | |
|---|---|
| `PEOPLE=solo\|shared` | whether live tasks sit at `work/current/` or `work/<owner>/current/`, and whether the append-only docs union-merge |
| `MACHINES=single\|multi` | whether `/save` stamps and pushes, and whether `/load` checks for cross-machine divergence |

Separate questions: one person with two computers is `solo` + `multi`. Unsure which applies? Ask
before writing into a task directory — on a shared install, writing into the wrong person's is
silent.

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
most expensive mistake this system prevents. Nothing is promoted to `[x]` on inference — only on
evidence, or on you saying you ran it. Every task carries a `Verify by:` naming what would prove it.

## Conventions worth knowing

- **Absolute dates only.** "Last session" means nothing to a cold reader three weeks later.
- **Supersede, don't overwrite.** A changed rule gets the old one struck through and the new one
  dated beside it. The reversal trail is usually worth more than the tidy version.
- **One home per fact.** What happened → `history.md` · why → `decisions.md` · temporary code →
  `hotfixes.md` · someone else's problem → `issues.md` · workspace gotcha → `traps.md`. Duplication
  across files is how half of them go quietly wrong.

## More than one person

Before anyone else clones this and runs `/start`, read `CLAUDE.md`'s "More than one person uses this
`.claude/`". The short version:

- **`/setup` runs once per project, ever — never on a clone**, where it would overwrite `CLAUDE.md`.
  Start with `/load`. Personal settings go in `settings.local.json` (gitignored).
- **Stamp every entry with an author.** The persistent docs merge with `merge=union`, which never
  conflicts about *anything* — including two edits to one entry. The stamp is what makes a silent
  duplicate visible. Read the tail after a merge.
- **Check `Owner:` in `hotfixes.md`.** Someone else's uncommitted hotfix is not in your tree.
- **Hook and `settings.json` changes go through a PR**, both ways. They execute on the other
  person's machine at session start, without them reading the diff.
- **`[x]` is per-machine.** Never promote someone else's `[~]` because their notes read as done.

## Backups

`backup_docs.sh` snapshots this directory to `~/.claude-backups/<project>/<date>/`, fired by hooks in
`settings.json`. **If `.claude/` is tracked by this project's git, you don't need it** — delete the
two hooks. It exists for when it isn't, and a same-disk daily copy is a weak substitute for version
control.

---

*Seeded from a working-docs template and free to diverge from it. Nothing here reaches back to that
template, and nothing you change needs sending back: this repository is the record of **this**
project's work, and it is yours to reshape.*
