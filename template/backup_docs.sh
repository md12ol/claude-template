#!/usr/bin/env bash
# Back up this project's .claude/ working docs.
#
# Insurance for the case where .claude/ is NOT tracked by the project's own git. If you do track it
# (recommended — see .claude/README.md), this is belt-and-braces and you can drop the hooks that
# call it.
#
# Snapshots land in ~/.claude-backups/<project-name>/<YYYY-MM-DD>/ — one directory per day,
# overwritten within the day, pruned beyond RETAIN_DAYS.
#
#   ./backup_docs.sh            # throttled; safe to call from a Stop hook after every turn
#   ./backup_docs.sh --force    # copy regardless of throttle (use for SessionEnd)

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$(basename "$(dirname "$SRC")")"
DEST_ROOT="${CLAUDE_DOCS_BACKUP_DIR:-$HOME/.claude-backups/$PROJECT}"
RETAIN_DAYS="${CLAUDE_DOCS_BACKUP_RETAIN:-14}"

# Everything that is not a directory. Add project-specific files here — anything living in
# .claude/ that you would not want to lose. The default list is the full working-doc set plus the
# settings, because settings.json holds the hooks that run this script.
DOCS=(
    CLAUDE.md
    README.md
    hooks-optional.md
    backup_docs.sh
    decisions.md
    issues.md
    hotfixes.md
    traps.md
    settings.json
    settings.local.json
)

# Directories copied whole: the active task, every archived task, and the skills themselves.
DIRS=(current archive skills)

DEST="$DEST_ROOT/$(date +%F)"

# Throttle: a Stop hook fires after every assistant turn, so skip if the snapshot is already fresh.
THROTTLE_SECS="${CLAUDE_DOCS_BACKUP_THROTTLE:-900}"
if [[ "${1:-}" != "--force" && -d "$DEST" && "$THROTTLE_SECS" -gt 0 ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$DEST") ))
    if (( age < THROTTLE_SECS )); then
        echo "backup skipped — snapshot is ${age}s old (throttle ${THROTTLE_SECS}s)"
        exit 0
    fi
fi

mkdir -p "$DEST"

copied=0
for f in "${DOCS[@]}"; do
    if [[ -s "$SRC/$f" ]]; then
        cp -p "$SRC/$f" "$DEST/$f"
        copied=$((copied + 1))
    fi
done

for d in "${DIRS[@]}"; do
    if [[ -d "$SRC/$d" ]]; then
        rm -rf "${DEST:?}/$d"
        cp -rp "$SRC/$d" "$DEST/$d"
    fi
done

# Prune old daily snapshots.
if [[ -d "$DEST_ROOT" ]]; then
    find "$DEST_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime "+$RETAIN_DAYS" -exec rm -rf {} + 2>/dev/null || true
fi

echo "backed up $copied docs + $(printf '%s ' "${DIRS[@]}")to $DEST"
