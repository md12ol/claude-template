#!/usr/bin/env bash
# PreToolUse(Edit|Write) — warn at the moment of the edit, not an hour after CLAUDE.md was read.
#
# Two cases:
#
#   1. Files outside your scope. CLAUDE.md's "files outside your scope" section names paths carrying
#      deliberate working-tree edits; the disposition is per-file, and only hotfixes.md knows which.
#      EDIT THE PATH PATTERN BELOW BEFORE ENABLING — the default is an example.
#
#   2. The .claude/ machinery itself. settings.json and hooks/*.sh execute on everyone ELSE's
#      machine at session start, on their next pull, without them reading the diff, so those changes
#      go through a PR. This branch needs no configuring and is worth keeping even solo.
#
# Never blocks — exit 0 always. Both kinds of edit are legitimate; they just need to be deliberate.
#
# Per-machine override: set CLAUDE_SCOPED_PATHS (an ERE) in .claude/settings.local.json to narrow
# case 1 to the files someone else is actually working on right now.
#
# Test:
#   echo '{"tool_input":{"file_path":"vendor/x.py"}}'                    | .claude/hooks/show_hotfixes.sh
#   echo '{"tool_input":{"file_path":".claude/hooks/session_brief.sh"}}' | .claude/hooks/show_hotfixes.sh

set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FILE="$(python3 -c 'import json,sys
try:
    t = json.load(sys.stdin).get("tool_input", {})
    print(t.get("file_path") or t.get("notebook_path") or "")
except Exception:
    print("")' 2>/dev/null)"

[[ -z "$FILE" ]] && exit 0

# ── 1. Files outside your scope ───────────────────────────────────────────────────────────────
# EDIT THIS — components owned by other people that carry deliberate working-tree edits. An
# out-of-date pattern that never fires is the same as no hook, so revisit it when ownership moves.
SCOPED="${CLAUDE_SCOPED_PATHS:-(^|/)(vendor|third_party)/}"

if grep -qE "$SCOPED" <<<"$FILE"; then
    cat <<EOF

⚠  $FILE is outside your scope — someone else may have live work in it.

CLAUDE.md: read hotfixes.md BEFORE editing, staging or reverting here, and check the Owner: line.
A hotfix owned by someone else is NOT in your working tree. The rules are not uniform — one file
may have to be committed and another must never be, and only the entry knows which.

hotfixes.md entries (heading · owner · where · remove-when):
EOF
    grep -nE '^### |^- \*\*(Owner|Machine|Where|Remove when):' "$DIR/work/hotfixes.md" 2>/dev/null \
        | sed 's/^/  /' | head -60

    if [[ -f "$DIR/work/collab.md" ]]; then
        echo
        echo "Open collab.md items — settle a conflict there rather than overwriting their work:"
        awk '/^## Open/{f=1;next} /^## /{f=0} f&&/^### /' "$DIR/work/collab.md" 2>/dev/null \
            | sed 's/^/  /' | head -20
    fi
    echo
fi

# ── 2. The .claude/ machinery ─────────────────────────────────────────────────────────────────
if grep -qE '(^|/)\.claude/(settings\.json|hooks/)' <<<"$FILE"; then
    cat <<EOF

⚠  $FILE runs on everyone else's machine.

settings.json and hooks/*.sh are executable code that fires at THEIR session start on their next
pull, without them reading it. CLAUDE.md: these changes go through a PR — never straight to main.
Say in the PR what the hook now does.

(settings.local.json is the per-machine escape hatch and is gitignored — use it for anything
personal, and nothing here applies.)

EOF
fi

exit 0
