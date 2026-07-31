# Optional hooks

`settings.json` ships with only the two backup hooks enabled. The three below turn `CLAUDE.md` rules
from prose into enforcement — worth adding, because prose rules do get violated.

To use one: copy its `"hooks"` contents into the `"hooks"` block in `settings.json`, merging by event
name, and edit the patterns. **Don't paste these headings or prose into `settings.json`** — it is
validated as strict JSON and unknown keys may be rejected.

Project-wide hooks belong in `settings.json` (tracked). Personal ones go in `settings.local.json`.

---

## 1. Block commands you run yourself

Enforces `CLAUDE.md` section 1 — "who runs the environment". Exit code `2` blocks the tool call and
shows the message to the agent, so it can adapt instead of failing blind.

**Edit the regex to match your commands.**

```json
"PreToolUse": [
  {
    "matcher": "Bash",
    "hooks": [
      {
        "type": "command",
        "command": "grep -qE '(docker compose up|make deploy|\\./run\\.sh)' <<<\"$CLAUDE_TOOL_INPUT\" && { echo 'Blocked by .claude/settings.json: the user runs this, not you. Hand off the exact command and the log markers for success/failure instead.' >&2; exit 2; } || exit 0"
      }
    ]
  }
]
```

## 2. Show `hotfixes.md` before editing someone else's file

`CLAUDE.md` says "read `hotfixes.md` before touching these paths". This shows it at the moment it
matters, rather than relying on the agent having read it an hour ago.

**Edit the path pattern** to the directories that carry deliberate working-tree edits.

```json
"PreToolUse": [
  {
    "matcher": "Edit|Write",
    "hooks": [
      {
        "type": "command",
        "command": "grep -qE 'path/to/owned/area' <<<\"$CLAUDE_TOOL_INPUT\" && cat \"$CLAUDE_PROJECT_DIR/.claude/work/hotfixes.md\" || true"
      }
    ]
  }
]
```

## 3. Session-start brief

Prints the top of the handoff plus counts of open / unverified / unfiled items, so orientation
happens even when you forget to type `/load`. Cheap, and it makes a rotting `[~]` or an unfiled issue
visible without asking.

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "cd \"$CLAUDE_PROJECT_DIR/.claude\" && [ -f current/handoff.md ] && { head -20 current/handoff.md; echo; echo \"open: $(grep -c '^- \\[ \\]' current/plan.md 2>/dev/null || echo 0)  unverified: $(grep -c '^- \\[~\\]' current/plan.md 2>/dev/null || echo 0)  unfiled issues: $(grep -c 'Filed:.*not yet' issues.md 2>/dev/null || echo 0)\"; } || true"
      }
    ]
  }
]
```

---

## Merging more than one

They share the `PreToolUse` event, so combine them into one array rather than repeating the key:

```json
"hooks": {
  "PreToolUse": [
    { "matcher": "Bash",       "hooks": [ { "type": "command", "command": "…hook 1…" } ] },
    { "matcher": "Edit|Write", "hooks": [ { "type": "command", "command": "…hook 2…" } ] }
  ],
  "SessionStart": [ … ],
  "SessionEnd":   [ … ],
  "Stop":         [ … ]
}
```

After editing, check it parses — a malformed `settings.json` disables every hook in it silently:

```bash
python3 -m json.tool .claude/settings.json > /dev/null && echo OK
```
