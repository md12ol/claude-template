# Hooks

Five scripts plus a shared library. **Only the backup is enabled by default**; `/setup` offers the
rest and wires up the ones that apply to how this project is configured.

A hook that never fires fails silently, which is why these ship as real scripts you can run rather
than as JSON snippets to paste.

| | Fires on | Needs editing first? |
|---|---|---|
| `lib.sh` | — sourced by the others | no — it reads `project.conf` and `work/owners.txt` |
| `backup_docs.sh` | `Stop`, `SessionEnd` | no — **enabled by default** |
| `block_env_commands.sh` | `PreToolUse(Bash)` | **yes** — the patterns are examples |
| `show_hotfixes.sh` | `PreToolUse(Edit\|Write)` | no |
| `pull_main.sh` | `SessionStart` | no — but only wire it when `MACHINES="multi"` |
| `session_brief.sh` | `SessionStart` | no |

Two more scripts live outside this directory because they are **not** hooks and are never wired into
`settings.json`: `cloud_setup.sh` here is run by hand on a fresh container, and
`../checks/cloud_ready.sh` is a read-only PASS/FAIL gate you can run anywhere.

Each is testable without a session:

```bash
.claude/hooks/session_brief.sh
.claude/hooks/pull_main.sh
.claude/checks/cloud_ready.sh
echo '{"tool_input":{"command":"git push --force"}}' | .claude/hooks/block_env_commands.sh; echo "exit $?"
```

## `lib.sh` — read this before editing any of the others

Everything project-specific comes from two files and nowhere else: `project.conf` (identity, host,
and the `PEOPLE`/`MACHINES` switches) and `work/owners.txt` (the email-to-directory table). `lib.sh`
exposes them as `claude_paths`, `load_conf`, `resolve_owner`, `other_owners`, `clone_hint`,
`is_shared` and `is_multi_machine`.

**If you find yourself adding a project name, a clone URL or a person's email to a hook, stop** —
it belongs in one of those two files. The system this template came from accumulated about thirty
copies of its own clone URL and a six-way duplicated owner table, and its own documentation had
gone stale about how many copies there were.

Every value has a default, so a missing or half-written `project.conf` degrades rather than taking
the session start down with it.

## 1. `block_env_commands.sh` — the only hook that changes what the agent can do

Three tiers. `ALLOW` is checked first and wins; `BLOCK` exits 2 and stops the command; `WARN`
proceeds but prints a notice the agent has to read.

**The WARN tier is the one people leave out and then want.** `git push` is legitimate when you asked
for it and a mistake when you did not — a hard block is wrong because you do ask for pushes, and
silence is wrong because by the time you notice an unasked push it is already outside the repo.

The shipped patterns span several ecosystems on purpose: they are examples to cut down, not a
policy. Keep the force-push and hard-reset blocks in every project — those destroy history that
someone else may already have fetched — and replace the rest with the commands you actually run
yourself.

**Watch for false positives when you edit.** A hook that blocks `make test` or `npm view` is a hook
someone disables, and then every real block it would have caught is gone too.

```json
"PreToolUse": [
  { "matcher": "Bash",
    "hooks": [{ "type": "command",
                "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/block_env_commands.sh\"" }] }
]
```

## 2. `show_hotfixes.sh` — surface temporary code before it is mistaken for a bug

Prints `hotfixes.md` when you edit a file that carries deliberate temporary edits, and warns when
you edit the `.claude/` machinery itself. The second branch needs no configuring and is worth
keeping even solo: `settings.json` and `hooks/` execute on everyone else's machine at session start
without them reading the diff.

## 3. `pull_main.sh` — fast-forward before a stale session starts

Fires first in `SessionStart`, before the brief, so the brief reflects whatever the other machine
pushed. It pulls the working-docs clone unconditionally (it is always on its own branch, so there is
no "am I mid-task" question) and the code repo only when its default branch is what is checked out —
read from `origin/HEAD` rather than assumed to be `main`.

**Only ever fast-forwards.** Local commits not on origin, or a working-tree change origin's version
would overwrite, and it prints one line and does nothing. It never merges, rebases, stashes or
discards.

**Wire it only when `project.conf` says `MACHINES="multi"`.** On a single-machine install it is a
network call at every session start that can never find anything.

```json
"SessionStart": [
  { "hooks": [
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/pull_main.sh\" 2>/dev/null || true", "timeout": 15 },
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/session_brief.sh\"" }
  ] }
]
```

## 4. `session_brief.sh` — orientation without `/load`

Prints the handoff's *Start here*, the counts that go stale silently (open `[ ]`, unverified `[~]`,
unfiled issues, traps), every parked task with what it is blocked on, and one line per other owner
with work in flight. No editing needed — it reads the shape from `lib.sh`.

It does **not** replace `/load`, which verifies the handoff against the repo. It makes a rotting
item visible at zero cost.

On an incomplete `.claude/` it prints the clone command and stops. That is the only missing-clone
case a hook can catch: if the directory were absent entirely, `settings.json` and this script would
be absent with it. The total case is covered by the project's root `CLAUDE.md` — see
`root_CLAUDE.md.example`.

## 5. `backup_docs.sh` — the one that is on by default

Snapshots the working docs to `~/.claude-backups/<project>/<date>/`. Same-disk and same-machine, so
it is a safety net against an accidental delete, not against a lost laptop, and it cannot tell you
*when* a doc went stale. Version control is the real answer; this is what you have until then.

## Changing any of these

**Hook and settings changes go through review**, on every layout and every team size. They execute
on everyone else's machine at session start, before they have read anything. This is the one part of
`.claude/` where "it is just docs" is false.
