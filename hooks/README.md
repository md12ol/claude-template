# Hooks

Five hooks plus `lib.sh`, which they all source. **`session_brief.sh` and `backup_docs.sh` are wired
by default**; `/setup` offers the rest and wires the ones that apply to this project. A hook that
never fires fails silently, which is why these ship as runnable scripts rather than as JSON snippets
to paste — each says what it does in its own header, including how to test it.

| | Fires on | Needs editing first? |
|---|---|---|
| `lib.sh` | — sourced by the others | no — it reads `project.conf` and `work/owners.txt` |
| `session_brief.sh` | `SessionStart` | no — **wired by default** |
| `backup_docs.sh` | `Stop`, `SessionEnd` | no — **wired by default** |
| `block_env_commands.sh` | `PreToolUse(Bash)` | **yes** — the shipped patterns are examples |
| `show_hotfixes.sh` | `PreToolUse(Edit\|Write)` | **yes** — the path pattern it matches on is an example |
| `pull_main.sh` | `SessionStart` | no — but only wire it when `MACHINES="multi"` |

Nothing else here is a hook. The scripts a person or a skill runs by hand live in `../bin/`:
`task.sh`, `setup_apply.sh`, `add_person.sh`, `comment_audit.sh` (reports the comment shapes
`../comment_style.md` forbids, in one file), and the cloud trio `cloud_env_setup.sh` (the reviewed
half of a cloud environment's own setup script), `cloud_setup.sh` (run once on a fresh container)
and `cloud_ready.sh` (a read-only PASS/FAIL gate, safe to run anywhere).

**`../settings.json` is what wires them up**, and it also carries the `attribution` block that keeps
agent trailers and session URLs out of commits and pull requests. It carries no description of its
own — JSON has no comment syntax, and an unknown key risks a strict validator rejecting the file and
silently disabling every hook in it — so this README is that documentation.

## `lib.sh` — read this before editing any of the others

Everything project-specific comes from two files and nowhere else: `project.conf` (identity, host,
and the `PEOPLE`/`MACHINES` switches) and `work/owners.txt` (the email-to-directory table). `lib.sh`
exposes them as `claude_paths`, `load_conf`, `resolve_owner`, `other_owners`, `clone_hint`,
`is_shared` and `is_multi_machine`. Every value has a default, so a missing or half-written
`project.conf` degrades rather than taking the session start down with it. **If you find yourself
adding a project name, a clone URL or a person's email to a hook, stop** — it belongs in one of
those two files. The system this template came from accumulated about thirty copies of its own clone
URL and a six-way duplicated owner table, and its own documentation had gone stale about how many.

## Wiring

`block_env_commands.sh` is the only hook that changes what the agent can do: `ALLOW` is checked
first and wins, `BLOCK` exits 2 and stops the command, `WARN` proceeds but prints a notice the agent
has to read.

```json
"PreToolUse": [
  { "matcher": "Bash",
    "hooks": [{ "type": "command",
                "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/block_env_commands.sh\"" }] }
]
```

`pull_main.sh` must run **before** the brief, so the brief reflects whatever the other machine
pushed. Wire it only when `project.conf` says `MACHINES="multi"`:

```json
"SessionStart": [
  { "hooks": [
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/pull_main.sh\" 2>/dev/null || true", "timeout": 15 },
      { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/session_brief.sh\"" }
  ] }
]
```

## Changing any of these

**Hook and settings changes go through review**, on every layout and team size: they execute on
everyone else's machine at session start, before anyone has read them. The one part of `.claude/`
where "it is just docs" is false.
