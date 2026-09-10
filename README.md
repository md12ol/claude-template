# claude-template

A portable working-docs system for [Claude Code](https://claude.com/claude-code). Six slash
commands and a file layout that stop sessions losing state between context clears.

Nothing here is language-, host- or team-specific. It works for one person on one laptop and for a
team across several machines, and the difference is two settings rather than two forks.

```
/setup   once per project — inspects the repo, asks what it can't infer, configures everything
/start   opens a task: objective + plan, before any code
/save    last thing before you stop, every session
/load    first thing when you come back
/park    set a blocked task down without losing it
/done    settles loose ends, archives the task
```

Three more ship optional, for teams that meet: `/make-agenda`, `/start-meeting`, `/end-meeting`.

## Why

Claude Code sessions are stateless, so every context clear costs you the reasoning behind the last
few days of work — silently. The next session resumes from a stale understanding and sounds
confident doing it. The usual patch is a `NOTES.md` nobody updates.

This makes the update a command, and gives each kind of fact exactly one home.

The highest-value behaviour is `/save`'s **loose-thread sweep**: before writing anything it re-reads
the session for things discussed but never landed — agreed-then-diverted, noticed-in-passing,
asked-and-unanswered — and asks about what it can't settle. Those are the items that evaporate on
`/clear`.

## Two layouts — pick one

### Fork (recommended)

The working docs get their own repository, cloned into place. Nothing about them touches your
project's history, ships inside a built artifact, or freezes on whatever branch you cut.

```bash
# 1. Fork this repo on your host — "Use this template" or "Fork" — naming it <project>-claude.
# 2. Clone YOUR fork and reshape it into a .claude/:
git clone <your-fork-url> myproj-claude && cd myproj-claude
/path/to/claude-template/install.sh --promote .
git add -A && git commit -m "Promote the template into this project's working docs" && git push

# 3. Clone it into the project it belongs to:
cd ~/code/myproj
git clone <your-fork-url> .claude
echo '.claude/' >> .gitignore          # the project must not track it as well
```

**A fork keeps its upstream link, and that is the point.** Improvements you make while working flow
back here as a pull request against upstream, and this template's improvements come to you with
`git fetch upstream && git merge upstream/main`. Copying files over the top loses authorship and
review; a fork does not.

`--promote` refuses to run while `origin` still points at this template, which is the mistake that
would push one project's working docs into the shared template's history.

### Copy

Plain files versioned by the project's own git. One repository, nothing to clone, no upstream link.
Right for a small project, a private experiment, or anywhere a second repository is overhead.

```bash
git clone https://github.com/<you>/claude-template.git ~/.claude-template   # once per machine
~/.claude-template/install.sh ~/code/my-project                             # once per project
```

Then, either way, open Claude Code in the project and run `/setup`. It reads the repo, asks two or
three questions with recommended answers pre-selected, writes `project.conf` and `CLAUDE.md`, and
wires up the hooks that apply. It runs once, and refuses to re-run over rules you've already earned.

The one question it always asks, because no repo reveals it: **which commands do you run yourself,
that the agent must not?** Name real commands and it wires up a hook that enforces them.

## The two switches

`/setup` asks two questions and writes the answers to `project.conf`. Everything else reads them, so
there is one place to change your mind.

| | `solo` / `single` | `shared` / `multi` |
|---|---|---|
| **`PEOPLE`** | live tasks at `work/current/` | `work/<owner>/current/`, union merge driver, `owners.txt`, `collab_settled.md` |
| **`MACHINES`** | nothing extra | `pull_main.sh`, the `Machine:` stamp, `/load`'s divergence check |

**They are separate questions and neither implies the other.** One person with a laptop and a
desktop is `solo` + `multi`, and has the full staleness problem with no teammate. A co-located pair
sharing one machine is `shared` + `single`. Inferring either from the other is wrong in both
directions.

## Layout

The split is **what Claude Code owns** vs **what you accumulate**:

```
.claude/
├── CLAUDE.md            rules, auto-loaded every session   ← /setup fills this in
├── project.conf         identity + the two switches        ← everything reads this
├── comment_style.md     one test, language-neutral
├── settings.json        hooks — backup enabled by default
├── settings.local.json  personal overrides (gitignored)
├── skills/              setup · start · save · load · park · done
├── skills-optional/     make-agenda · start-meeting · end-meeting
├── hooks/               lib.sh + backup + 4 optional scripts
├── checks/              cloud_ready.sh — read-only PASS/FAIL
├── codex/               optional bridge: same workflows, no forked copies
└── work/                ── everything YOU accumulate ──
    ├── owners.txt       the ONLY email→directory table
    ├── decisions.md     append-only: what was chosen and why
    ├── issues.md        work for other people, staged for the tracker
    ├── hotfixes.md      temporary code, each with a Remove when:
    ├── traps.md         permanent workspace gotchas
    ├── traps_retired.md fixed traps, each naming the fix
    ├── deferred.md      wanted, not now — no dates, no ordering
    ├── collab.md        cross-owner questions (delete if solo)
    ├── current/         the active task
    ├── parked/          blocked tasks, each with a Blocked on:
    ├── archive/         finished tasks, <YYYY-MM>_<slug>/
    └── meetings/        one file per sitting (optional)
```

Claude Code reads `CLAUDE.md`, `settings*.json` and `skills/*/SKILL.md` at those exact paths — they
can't move. Everything under `work/` is yours.

## Task vs project

One question decides where something goes: **does it stop being true when the task ends?**

| | | |
|---|---|---|
| `plan.md` · `history.md` · `handoff.md` | task | dead once the objective is met |
| `decisions.md` | **project** | the choice still constrains the code |
| `hotfixes.md` | **project** | the band-aid is still in the tree |
| `issues.md` | **project** | the bug doesn't stop existing |
| `traps.md` | **project** | the workspace still behaves that way |
| `deferred.md` | **project** | still wanted, still not now |
| `collab.md` | **project** | coordination outlives any one task |

Project files: **one of each, forever.** Task files: **one set live at a time** — `/done` moves it to
`archive/`, `/park` moves it to `parked/`, `/start` refuses to run until it's empty.

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
inference — only on evidence, or on you saying you ran it. Every task carries a `Verify by:` line,
and `/save` stamps each `[~]` with the date it went unverified so a stale one looks stale.

## Commands

| | |
|---|---|
| `install.sh --promote [dir]` | reshape a fresh fork into a working-docs repo |
| `install.sh <project>` | copy layout: seed a new `.claude/`. Never clobbers existing files |
| `install.sh --update <project>` | copy layout: refresh `skills/`, `hooks/`, `checks/`, `output-styles/`, `codex/` |
| `install.sh --export <project>` | copy layout: pull a project's improved machinery **back** here |
| `install.sh --diff <project>` | show what differs. Changes nothing |
| `install.sh --with-meetings <project>` | also install the three meeting skills |

On the fork layout, `--update` and `--export` are the wrong tools and say so: pull from upstream, and
open a pull request back to it.

## Hooks

`hooks/` ships five scripts plus `lib.sh`; only the backup is enabled. See `hooks/README.md` —
`/setup` offers the rest and wires up the ones that apply.

| | |
|---|---|
| `lib.sh` | reads `project.conf` and `owners.txt` for every other script. **Nothing else hardcodes them** |
| `backup_docs.sh` | snapshots to `~/.claude-backups/<project>/<date>/`. **On by default** |
| `block_env_commands.sh` | three tiers: allow · warn · block. Prose rules get violated; exit 2 doesn't |
| `show_hotfixes.sh` | prints `hotfixes.md` when editing a file that carries deliberate edits |
| `pull_main.sh` | fast-forwards before a stale session starts. Only when `MACHINES=multi` |
| `session_brief.sh` | handoff, counts, parked tasks and blockers at session start |

Plus `hooks/cloud_setup.sh` and `checks/cloud_ready.sh` for containers — run by hand, never wired.

## Codex

`codex/` makes the same workflows available to Codex. Wrappers are **generated** from the canonical
skills, never forked, so a change to a workflow reaches both hosts at once:

```bash
.claude/codex/install.sh      # once per clone; .ps1 for native Windows
.claude/codex/check_bridge.sh # after adding, removing or renaming a skill
```

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
- **Union merge covers three files, not all of them.** The churn lists allow deletion, and union
  cannot express one: a delete racing any edit to the same region is silently discarded and the
  entry comes back.
- **One copy of the owner table.** The source project reached six copies plus about thirty
  hardcoded clone URLs, and its own documentation had gone stale about how many copies there were.

## Licence

MIT.
