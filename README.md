# claude-template

A portable working-docs system for [Claude Code](https://claude.com/claude-code): four slash
commands (`/start`, `/save`, `/load`, `/done`) and the file layout they maintain, so sessions stop
losing state between context clears.

Copy it into any project in one command. Nothing in here is language- or framework-specific.

## The problem it solves

Claude Code sessions are stateless. Without something durable, every context clear costs you the
reasoning behind the last three days of work, and the failure is silent — the next session confidently
resumes from a stale understanding. The usual patch is a `NOTES.md` that nobody updates.

This makes the update a command, and puts each kind of fact in exactly one file:

| | |
|---|---|
| what happened | `current/history.md` |
| why | `decisions.md` |
| what's next | `current/plan.md`, `current/handoff.md` |
| temporary code in the tree | `hotfixes.md` |
| someone else's problem | `issues.md` |
| permanent workspace gotchas | `traps.md` |

The most valuable single behaviour is `/save`'s **loose-thread sweep**: before writing anything, it
re-reads the session for things that were discussed but never landed — agreed-then-diverted,
noticed-in-passing, asked-and-unanswered — and asks you about the ones it can't settle itself. Those
are the items that evaporate on `/clear`.

## Install

```bash
git clone https://github.com/<you>/claude-template.git ~/.claude-template
~/.claude-template/install.sh ~/code/my-project
```

That creates `~/code/my-project/.claude/` with the skills, a `CLAUDE.md` to fill in, seeded doc
templates, and empty `current/` + `archive/`. It **never overwrites an existing file** — safe to
re-run.

Then open Claude Code in the project and run:

```
/setup
```

`/setup` reads the repo first — build manifests, submodules, git remote, whether `.claude/` is
gitignored — then asks only what it can't infer, and writes `CLAUDE.md` for you. It runs **once,
ever**, and refuses to re-run over rules you've already earned.

The one thing it always asks, because no repo reveals it: **which commands you run yourself and the
agent must not.** Answer with actual command names and it will offer to enforce them with a hook,
so the rule holds instead of merely being written down.

Then `/start` your first task. Expect five minutes, most of it clicking through recommended answers.

*Prefer to do it by hand?* Work through the four `FILL IN` blocks in `.claude/CLAUDE.md` and delete
what doesn't apply — a single-repo project with no tracker deletes three of them.

### Don't clone it *into* the project

The template is a **source you copy from**, not a repo you check out. Cloning it into a project makes
`.claude/` a nested git repo, and a branch-per-project means every project's `plan.md` and
`history.md` end up committed to this shared repo — so pulling a skill improvement into project B
becomes a merge across unrelated content. `install.sh` copies plain files instead; the project's own
git versions them.

## Commands

| | |
|---|---|
| `install.sh <project>` | seed a new `.claude/`. Never clobbers existing files |
| `install.sh --update <project>` | refresh `skills/` + `backup_docs.sh` only. Leaves `CLAUDE.md` and all project content alone |
| `install.sh --export <project>` | pull that project's improved skills **back** into this template, ready to commit |
| `install.sh --diff <project>` | show what differs between template and project. Changes nothing |

The `--export` direction matters: you will improve a skill while working in some project, and
without it that improvement stays stranded there.

```bash
~/.claude-template/install.sh --export ~/code/my-project
cd ~/.claude-template && git diff && git commit -am "save: sharpen the loose-thread sweep"
```

## What you get in a project

```
.claude/
├── CLAUDE.md              rules, loaded into every session  ← you fill this in
├── README.md              explains the system to you and teammates
├── settings.json          hooks (backup on by default, three more commented out)
├── backup_docs.sh         snapshots to ~/.claude-backups/<project>/<date>/
├── skills/
│   ├── setup/SKILL.md     once per project: inspect the repo, fill in CLAUDE.md
│   ├── start/SKILL.md     agree the objective, write the plan, before any code
│   ├── save/SKILL.md      sweep for loose threads, update every doc, write the handoff
│   ├── load/SKILL.md      read the handoff, verify it against the repo, report, stop
│   └── done/SKILL.md      settle every loose end, then archive
├── decisions.md           append-only: what was chosen and why
├── issues.md              work for other people, staged for the tracker
├── hotfixes.md            temporary code, each with a Remove when:
├── traps.md               permanent workspace gotchas
├── current/               the active task (empty until /start)
└── archive/               finished tasks, <YYYY-MM>_<slug>/
```

## The three task states

```
[ ]  pending
[~]  done but NOT verified      ← the one that matters
[x]  done AND verified
```

`[~]` exists because "it compiles" and "it works" are different claims. Nothing is promoted to `[x]`
on inference — only on evidence, or on you saying you ran it. Every task carries a `Verify by:` line
naming what would prove it, and `/save` stamps each `[~]` with the date it went unverified so a stale
one is visible as stale.

## Track `.claude/` in your project's git

`install.sh` warns if `.claude/` is gitignored, because that is this system's biggest fragility:
`CLAUDE.md`, the skills, `hotfixes.md` and `decisions.md` then have no version control, no recovery,
no history — and teammates never see them. `hotfixes.md` in particular documents deliberate edits to
other people's files; anyone who checks out the branch gets those edits and none of the explanation.

Recommended `.gitignore` — track the machinery, ignore only what's personal or ephemeral:

```gitignore
.claude/settings.local.json
.claude/current/
.claude/archive/
```

If you'd rather keep the whole thing untracked, leave the backup hooks enabled — but a same-disk
daily copy is a weak substitute for version control, and it can't tell you *when* a doc went stale.

## Optional hooks

`settings.json` ships four hooks: two backup hooks enabled, three more commented out under
`_optional_*` keys. Copy any into the `hooks` block and edit the patterns.

| | |
|---|---|
| **Block dangerous commands** | Enforces `CLAUDE.md`'s "who runs the environment" rule at the tool call, instead of hoping prose is obeyed. Prose rules do get violated |
| **Show hotfixes before editing owned files** | Prints `hotfixes.md` when the agent is about to edit a file carrying a deliberate working-tree edit |
| **Session-start brief** | Prints the handoff plus counts of open / unverified / unfiled items, so orientation happens even if you forget `/load` |

## Design notes

A few rules here exist because their absence caused a specific, expensive failure:

- **`plan.md` has a soft cap of ~600 lines**, and completed items are compressed to ≤ 3 lines *when
  ticked*. In the project this came from, the plan reached 1432 lines and had to be halved by hand;
  evidence and rationale had piled into a file that owns neither.
- **Never leave a superseded item wearing a `[ ]`.** Nine permanently-unticked "kept for the
  reasoning" items taught everyone to skim past `[ ]` — which is how a real pending item gets lost.
  Superseded wording moves to `plan_superseded.md`.
- **`traps.md` exists** because durable warnings kept being parked in `handoff.md`, which `/save`
  overwrites every session. They were deleted the moment they stopped being top-of-mind.
- **`/done` should fire regularly.** One "task" that ran 13 sessions produced a 1345-line plan, a
  3263-line history, an empty `archive/`, and a `/load` that cost real context before any work
  started.

## Licence

MIT. Do what you like with it.
