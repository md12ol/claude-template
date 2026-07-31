# claude-template

A portable working-docs system for [Claude Code](https://claude.com/claude-code). Five slash commands
and a file layout that stop sessions losing state between context clears.

Drop it into any project in one command. Nothing here is language- or framework-specific.

```
/setup   once per project — inspects the repo, writes CLAUDE.md
/start   opens a task: objective + plan, before any code
/save    last thing before you stop, every session
/load    first thing when you come back
/done    settles loose ends, archives the task
```

## Why

Claude Code sessions are stateless, so every context clear costs you the reasoning behind the last
few days of work — silently. The next session resumes from a stale understanding and sounds confident
doing it. The usual patch is a `NOTES.md` nobody updates.

This makes the update a command, and gives each kind of fact exactly one home.

The highest-value behaviour is `/save`'s **loose-thread sweep**: before writing anything it re-reads
the session for things discussed but never landed — agreed-then-diverted, noticed-in-passing,
asked-and-unanswered — and asks about what it can't settle. Those are the items that evaporate on
`/clear`.

## Install

```bash
git clone https://github.com/<you>/claude-template.git ~/.claude-template   # once per machine
~/.claude-template/install.sh ~/code/my-project                             # once per project
```

Then open Claude Code in that project and run `/setup`. It reads the repo, asks two or three
questions with recommended answers pre-selected, writes `CLAUDE.md`, and offers the optional hooks.
It runs once, and refuses to re-run over rules you've already earned.

The one question it always asks, because no repo reveals it: **which commands do you run yourself,
that the agent must not?** Name real commands and it wires up a hook that enforces them.

Then `/start` your first task.

> **Don't clone it *into* a project.** That makes `.claude/` a nested git repo, and a
> branch-per-project puts every project's `plan.md` into this shared history. `install.sh` copies
> plain files; the project's own git versions them.

## Layout

The split is **what Claude Code owns** vs **what you accumulate**:

```
.claude/
├── CLAUDE.md            rules, auto-loaded every session   ← you fill this in
├── README.md            explains the system to teammates
├── settings.json        hooks — backup enabled by default
├── settings.local.json  personal overrides (gitignored)
├── skills/              setup · start · save · load · done
├── hooks/               backup_docs.sh + 3 optional enforcement scripts
└── work/                ── everything YOU accumulate ──
    ├── decisions.md     append-only: what was chosen and why
    ├── issues.md        work for other people, staged for the tracker
    ├── hotfixes.md      temporary code, each with a Remove when:
    ├── traps.md         permanent workspace gotchas
    ├── current/         the active task
    ├── archive/         finished tasks, <YYYY-MM>_<slug>/
    └── reference/       project docs that aren't session state
```

Claude Code reads `CLAUDE.md`, `settings*.json` and `skills/*/SKILL.md` at those exact paths — they
can't move. Everything under `work/` is yours.

## Task vs project

One question decides where something goes: **does it stop being true when the task ends?**

| | | |
|---|---|---|
| `work/current/plan.md` | task | dead once the objective is met |
| `work/current/plan_superseded.md` | task | original wording of those tasks |
| `work/current/history.md` | task | the session log *of that task* |
| `work/current/handoff.md` | task | a prompt to resume a task that's over |
| `decisions.md` | **project** | the choice still constrains the code |
| `hotfixes.md` | **project** | the band-aid is still in the tree |
| `issues.md` | **project** | the bug doesn't stop existing |
| `traps.md` | **project** | the workspace still behaves that way |

Project files: **one of each, forever.** Task files: **one set live at a time** — `current/` holds
exactly one task, `/done` moves it to `archive/`, `/start` refuses to run until it's empty.

### Routing

| Question | File |
|---|---|
| Would a newcomer ask *"why is it like this?"* | `decisions.md` |
| Is there code in the tree I want to delete later? | `hotfixes.md` |
| Is this someone else's to fix? | `issues.md` |
| Will this waste my time again, with nothing to fix? | `traps.md` |
| Did something happen this session? | `history.md` |
| Is there work left to do? | `plan.md` |

The confusable pair is `hotfixes` vs `traps`. A hotfix is **code you added and want gone**; a trap is
**how the workspace behaves and always will**. A hardcoded scale factor is a hotfix. `grep -r`
silently skipping symlinked directories is a trap.

## Task states

```
[ ]  pending
[~]  done but NOT verified      ← the one that matters
[x]  done AND verified
```

`[~]` exists because "it compiles" and "it works" are different claims. Nothing reaches `[x]` on
inference — only on evidence, or on you saying you ran it. Every task carries a `Verify by:` line, and
`/save` stamps each `[~]` with the date it went unverified so a stale one looks stale.

## Commands

| | |
|---|---|
| `install.sh <project>` | seed a new `.claude/`. Never clobbers existing files |
| `install.sh --update <project>` | refresh `skills/` + `hooks/` only; leaves your content alone |
| `install.sh --export <project>` | pull a project's improved skills **back** here, ready to commit |
| `install.sh --diff <project>` | show what differs. Changes nothing |

`--export` matters: you'll improve a skill while working in some project, and without it that
improvement stays stranded there.

```bash
~/.claude-template/install.sh --export ~/code/my-project
cd ~/.claude-template && git diff && git commit -am "save: sharpen the sweep"
```

## Track `.claude/` in your project's git

`install.sh` warns if it's gitignored, because that's this system's biggest fragility — no version
control, no recovery, no history, and teammates never see it. `hotfixes.md` especially documents
deliberate edits to other people's files; anyone checking out the branch gets the edits and none of
the explanation.

```gitignore
.claude/settings.local.json
.claude/work/current/
.claude/work/archive/
```

If you'd rather keep it untracked, leave the backup hooks on — but a same-disk daily copy can't tell
you *when* a doc went stale.

## Hooks

`hooks/` ships four scripts; only the backup is enabled. See `hooks/README.md` — `/setup` offers the
rest and wires them up.

| | |
|---|---|
| `backup_docs.sh` | snapshots to `~/.claude-backups/<project>/<date>/`. **On by default** |
| `block_env_commands.sh` | refuses commands you reserve for yourself. Prose rules get violated; exit 2 doesn't |
| `show_hotfixes.sh` | prints `hotfixes.md` when editing a file that carries deliberate edits |
| `session_brief.sh` | handoff + counts at session start, in case you forget `/load` |

## Design notes

Rules that exist because their absence cost something specific:

- **`plan.md` soft-caps at ~600 lines**, completed items compressed to ≤3 lines *when ticked*. The
  source project's plan hit 1432 lines and had to be halved by hand.
- **Never leave a superseded item wearing `[ ]`.** Nine permanently-unticked "kept for the reasoning"
  entries taught everyone to skim past `[ ]` — which is how a real pending item gets lost.
- **`traps.md` exists** because durable warnings kept being parked in `handoff.md`, which `/save`
  overwrites every session. One had gone silently wrong before anyone re-tested it.
- **`/done` should fire regularly.** One "task" ran 13 sessions and produced a 1345-line plan, a
  3263-line history, and an empty `archive/`.

## Licence

MIT.
