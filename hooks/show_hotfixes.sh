#!/usr/bin/env bash
# PreToolUse(Edit|Write) — warn at the moment of the edit, not an hour after CLAUDE.md was read.
# Two cases:
#   1. Files outside your scope — paths carrying deliberate working-tree edits, whose disposition is
#      per-file and only hotfixes.md knows. EDIT THE PATH PATTERN BELOW BEFORE ENABLING; it is an
#      example. Per-machine override: CLAUDE_SCOPED_PATHS (an ERE) in settings.local.json.
#      On a TRACKER_FIRST install there is no hotfixes.md: it lists the file's own TEMPORARY (
#      markers instead, which is where temporary code records itself there.
#   2. The .claude/ machinery itself. settings.json and hooks/*.sh execute on everyone ELSE's machine
#      at session start, without them reading the diff. Needs no configuring; keep it even solo.
#
# Never blocks — exit 0 always. Both kinds of edit are legitimate; they just need to be deliberate.
#
# Test:
#   echo '{"tool_input":{"file_path":"vendor/x.py"}}'                    | .claude/hooks/show_hotfixes.sh
#   echo '{"tool_input":{"file_path":".claude/hooks/session_brief.sh"}}' | .claude/hooks/show_hotfixes.sh

set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
claude_paths
load_conf
DIR="$CLAUDE_DIR"

FILE="$(python3 -c 'import json,sys
try:
    t = json.load(sys.stdin).get("tool_input", {})
    print(t.get("file_path") or t.get("notebook_path") or "")
except Exception:
    print("")' 2>/dev/null)"

[[ -z "$FILE" ]] && exit 0

# ── 1. Files outside your scope ───────────────────────────────────────────────────────────────
# EDIT THIS — a pattern that never fires is the same as no hook, so revisit it as ownership moves.
SCOPED="${CLAUDE_SCOPED_PATHS:-(^|/)(vendor|third_party)/}"

if grep -qE "$SCOPED" <<<"$FILE"; then
    if is_tracker_first; then
        cat <<EOF

⚠  $FILE is outside your scope; someone else may have live work in it.

CLAUDE.md: temporary code here is a TEMPORARY ( marker plus the issue whose closure removes it.
Read the markers below and their issues BEFORE editing, staging or reverting.
EOF
        for p in "$FILE" "$PROJECT_DIR/$FILE"; do
            [[ -f "$p" ]] && { grep -n "TEMPORARY (" "$p" | sed 's/^/  /' | head -20; break; }
        done
    else
        cat <<EOF

⚠  $FILE is outside your scope — someone else may have live work in it.

CLAUDE.md: read hotfixes.md BEFORE editing, staging or reverting here, and check its Owner: line.
The rules are per-file — one may have to be committed, another never — and only the entry knows.
hotfixes.md entries (heading · owner · where · remove-when):
EOF
        grep -nE '^### |^- \*\*(Owner|Machine|Where|Remove when):' "$DIR/work/hotfixes.md" 2>/dev/null \
            | sed 's/^/  /' | head -60
    fi

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

settings.json and hooks/*.sh fire at THEIR session start on their next pull, without them reading
it. CLAUDE.md: these go through a PR, never straight to main — say what the hook now does.
(settings.local.json is the gitignored per-machine escape hatch; nothing here applies to it.)
EOF
fi

exit 0
