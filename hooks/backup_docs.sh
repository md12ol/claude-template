#!/usr/bin/env bash
# Back up this project's .claude/ working docs.
#
# Insurance for a .claude/ that is not its own clone; with one, the hooks calling it can go.
# Snapshots land in ~/.claude-backups/<project>/<YYYY-MM-DD>/, one per day, overwritten within the
# day, pruned beyond RETAIN_DAYS. The project name is the directory containing .claude/, so nothing
# needs configuring per project.
#
#   .claude/hooks/backup_docs.sh            # throttled; safe from a Stop hook after every turn
#   .claude/hooks/backup_docs.sh --force    # copy regardless of throttle (use for SessionEnd)

set -euo pipefail

CLAUDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$(basename "$(dirname "$CLAUDE_DIR")")"
DEST_ROOT="${CLAUDE_DOCS_BACKUP_DIR:-$HOME/.claude-backups/$PROJECT}"
RETAIN_DAYS="${CLAUDE_DOCS_BACKUP_RETAIN:-14}"

# Loose files at the .claude/ root. settings.json holds the hooks that run this script: without it
# a restore cannot restore its own trigger.
DOCS=(
    CLAUDE.md
    README.md
    settings.json
    settings.local.json
)

# Copied whole. work/ is the point of the backup; skills/ and hooks/ are cheap to include and
# annoying to rebuild by hand.
DIRS=(work skills hooks)

DEST="$DEST_ROOT/$(date +%F)"

# Throttle: a Stop hook fires after every assistant turn, so skip if the snapshot is already fresh.
THROTTLE_SECS="${CLAUDE_DOCS_BACKUP_THROTTLE:-900}"
if [[ "${1:-}" != "--force" && -d "$DEST" && "$THROTTLE_SECS" -gt 0 ]]; then
    age=$(( $(date +%s) - $(stat -c %Y "$DEST") ))
    if (( age < THROTTLE_SECS )); then
        echo "backup skipped: snapshot is ${age}s old (throttle ${THROTTLE_SECS}s)"
        exit 0
    fi
fi

mkdir -p "$DEST"

copied=0
for f in "${DOCS[@]}"; do
    if [[ -s "$CLAUDE_DIR/$f" ]]; then
        cp -p "$CLAUDE_DIR/$f" "$DEST/$f"
        copied=$((copied + 1))
    fi
done

for d in "${DIRS[@]}"; do
    if [[ -d "$CLAUDE_DIR/$d" ]]; then
        rm -rf "${DEST:?}/$d"
        cp -rp "$CLAUDE_DIR/$d" "$DEST/$d"
    fi
done

# Prune old daily snapshots.
if [[ -d "$DEST_ROOT" ]]; then
    find "$DEST_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime "+$RETAIN_DAYS" -exec rm -rf {} + 2>/dev/null || true
fi

echo "backed up $copied files + $(printf '%s ' "${DIRS[@]}")to $DEST"
