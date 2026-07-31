#!/usr/bin/env bash
# Install / update / export the .claude working-docs system.
#
#   install.sh <project-dir>            seed a new .claude/ (never clobbers existing files)
#   install.sh --update <project-dir>   refresh skills/ + hooks/ only
#   install.sh --export <project-dir>   pull that project's skills back into this template
#   install.sh --diff   <project-dir>   show what differs, change nothing
#
# The template is a SOURCE you copy from, not a repo you check out into a project. That keeps the
# project's .claude/ as plain files versioned by the project's own git, with no nested repo and no
# project state leaking into this template's history.

set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$TEMPLATE_DIR/template"

# Machinery the template owns and may refresh. Everything else in a project's .claude/ is that
# project's own content and is never touched by --update.
MACHINERY_DIRS=(skills hooks)

# Written once at install, never overwritten afterwards — these accumulate project content.
# Paths are relative to .claude/.
SEEDED=(CLAUDE.md README.md settings.json
        work/decisions.md work/issues.md work/hotfixes.md work/traps.md work/collab.md)

die() { echo "error: $*" >&2; exit 1; }

MODE=install
case "${1:-}" in
    --update) MODE=update; shift ;;
    --export) MODE=export; shift ;;
    --diff)   MODE=diff;   shift ;;
    -h|--help|"") sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) die "unknown flag: $1" ;;
esac

TARGET_PROJECT="${1:-}"
[[ -n "$TARGET_PROJECT" ]] || die "no project directory given"
[[ -d "$TARGET_PROJECT" ]] || die "not a directory: $TARGET_PROJECT"
TARGET_PROJECT="$(cd "$TARGET_PROJECT" && pwd)"
DEST="$TARGET_PROJECT/.claude"

case "$MODE" in

install)
    echo "installing .claude/ into $TARGET_PROJECT"
    mkdir -p "$DEST"/work/{current,archive,reference} "$DEST"/{skills,hooks}

    skipped=0 written=0
    for f in "${SEEDED[@]}"; do
        if [[ -e "$DEST/$f" ]]; then
            echo "  skip     $f (already exists)"
            skipped=$((skipped + 1))
        else
            cp "$SRC/$f" "$DEST/$f"
            echo "  write    $f"
            written=$((written + 1))
        fi
    done

    for d in "${MACHINERY_DIRS[@]}"; do
        mkdir -p "$DEST/$d"
        cp -r "$SRC/$d/." "$DEST/$d/"
        chmod +x "$DEST/$d"/*.sh 2>/dev/null || true
        echo "  write    $d/"
    done

    # settings.local.json is personal; seed an empty one and make sure git ignores it.
    [[ -e "$DEST/settings.local.json" ]] || echo '{}' > "$DEST/settings.local.json"

    # Recommend tracking .claude/ in the project's git, but never edit .gitignore silently.
    echo
    echo "wrote $written, skipped $skipped."
    if [[ -d "$TARGET_PROJECT/.git" ]] && git -C "$TARGET_PROJECT" check-ignore -q .claude 2>/dev/null; then
        cat <<'WARN'

⚠  .claude/ is gitignored in this project.

   That is the single biggest fragility in this system: CLAUDE.md, the skills, hotfixes.md and
   decisions.md then have no version control and no recovery path, and teammates never see them.

   Recommended .gitignore instead — track the machinery, ignore only what is personal:

       .claude/settings.local.json
       .claude/work/current/

   work/current/ is the ONE thing to keep per-person: two people cannot hold one live plan.
   work/archive/ is deliberately NOT ignored — a finished task's record is shared history, and
   ignoring it strands every /done on one laptop.

   If you keep .claude/ ignored, leave the backup hooks in settings.json enabled.
WARN
    fi

    # Shared repo? The append-only docs need a union merge driver or they conflict constantly.
    if [[ -d "$TARGET_PROJECT/.git" ]] \
       && ! grep -qs 'claude/work/\*\.md' "$TARGET_PROJECT/.gitattributes"; then
        cat <<'WARN'

ℹ  If more than one person will use this .claude/, add to the repo root .gitattributes:

       .claude/work/*.md merge=union

   decisions.md, traps.md, hotfixes.md, issues.md and collab.md are append-only, so everyone
   writes to the tail of the same file — without this, every concurrent session ends in a merge
   conflict. The trade: union merge NEVER conflicts, so a real collision on the same entry merges
   silently. Stamp every entry with an author so a duplicate is visible. See CLAUDE.md,
   "More than one person uses this .claude/".
WARN
    fi
    cat <<EOF

Next — open Claude Code in this project and run:

    /setup

It inspects the repo, asks what it can't infer, and fills in CLAUDE.md for you. Once, ever.
Then /start your first task.

(Prefer to do it by hand? Work through the FILL IN blocks in $DEST/CLAUDE.md and delete
what doesn't apply. $DEST/README.md explains the system.)
EOF
    ;;

update)
    [[ -d "$DEST" ]] || die "no .claude/ in $TARGET_PROJECT — run install first"
    echo "refreshing machinery in $DEST (CLAUDE.md and all project content left alone)"
    for d in "${MACHINERY_DIRS[@]}"; do
        cp -r "$SRC/$d/." "$DEST/$d/"
        chmod +x "$DEST/$d"/*.sh 2>/dev/null || true
        echo "  update   $d/"
    done
    echo "done. Project content untouched: ${SEEDED[*]}"
    ;;

export)
    [[ -d "$DEST" ]] || die "no .claude/ in $TARGET_PROJECT"
    echo "pulling machinery from $DEST back into the template"
    for d in "${MACHINERY_DIRS[@]}"; do
        [[ -d "$DEST/$d" ]] && { cp -r "$DEST/$d/." "$SRC/$d/"; echo "  export   $d/"; }
    done
    echo
    echo "Review and commit in the template repo:"
    echo "  cd $TEMPLATE_DIR && git diff && git commit -am 'skills: <what changed>'"
    ;;

diff)
    [[ -d "$DEST" ]] || die "no .claude/ in $TARGET_PROJECT"
    for d in "${MACHINERY_DIRS[@]}"; do
        diff -ru "$SRC/$d" "$DEST/$d" || true
    done
    ;;
esac
