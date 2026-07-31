#!/usr/bin/env bash
# PreToolUse(Bash) — enforce CLAUDE.md's "who runs the environment" rule.
#
# Prose rules get violated; exit code 2 does not. /setup builds the patterns below from the commands
# you name, or edit BLOCK/ALLOW by hand.
#
# EDIT THESE TWO PATTERNS BEFORE ENABLING — the defaults are examples, not your project.
#
# Reads the hook JSON on stdin, blocks on a match, and tells the agent what to do instead.
# Exit 0 = allow, exit 2 = block (the message on stderr goes back to the agent).
#
# Test:
#   echo '{"tool_input":{"command":"make deploy"}}' | .claude/hooks/block_env_commands.sh; echo "rc=$?"

set -uo pipefail

CMD="$(python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    print("")' 2>/dev/null)"

[[ -z "$CMD" ]] && exit 0

# Blocked: the commands the user runs themselves. Word-boundaried so it does not fire on
# substrings (e.g. `echo deploying` must not match `deploy`).
BLOCK='(^|[^[:alnum:]_./-])(make[[:space:]]+deploy|docker[[:space:]]+compose[[:space:]]+up)([^[:alnum:]_-]|$)'
BLOCK+='|\./deploy\.sh'
BLOCK+='|\./run\.sh'

# Explicitly allowed even though they resemble the blocked ones — read-only analysis of
# already-generated output. Leave empty (ALLOW='^$') if there are no such exceptions.
ALLOW='^$'

if grep -qE "$ALLOW" <<<"$CMD"; then
    exit 0
fi

if grep -qE "$BLOCK" <<<"$CMD"; then
    cat >&2 <<EOF
BLOCKED by .claude/hooks/block_env_commands.sh

CLAUDE.md reserves this command for the user to run.

Command refused:
  $CMD

Do this instead: make the code/config change, then hand over the EXACT command to run and
the log markers that indicate success or failure. Then stop and wait.

Still allowed: reading already-generated output (logs, reports, result directories) and any
git / grep / file inspection.
EOF
    exit 2
fi

exit 0
