#!/usr/bin/env bash
# Set up the .claude working-docs system in a project.
#
#   install.sh --promote [dir]          turn a fresh FORK of this template into a working-docs repo
#   install.sh <project-dir>            copy layout: seed a plain .claude/ (never clobbers)
#   install.sh --update <project-dir>   copy layout: refresh the machinery only
#   install.sh --export <project-dir>   copy layout: pull that project's machinery back here
#   install.sh --diff   <project-dir>   show what differs, change nothing
#
# TWO LAYOUTS, and the choice is real:
#
#   FORK (recommended, and what --promote is for). Fork this template into <project>-claude, run
#   --promote in the fork, push, then clone it as .claude/ inside your project. The working docs
#   are their own repository, so they never appear in your project's history, never ship inside a
#   built artifact, and are never frozen on whatever branch you cut. Improvements flow back here as
#   a pull request against upstream, which is what a fork is for.
#
#   COPY (the original, still fully supported). Plain files versioned by the project's own git. One
#   repository, nothing to clone, and no upstream link — you carry improvements across by hand.
#   Right for a small project, a private experiment, or anywhere a second repository is overhead.
#
# /setup asks nothing about this: it detects which layout it is in.

set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$TEMPLATE_DIR/template"

# Machinery the template owns and may refresh. Everything else in a project's .claude/ is that
# project's own content and is never touched by --update.
MACHINERY_DIRS=(skills hooks checks output-styles codex)

# Written once at install, never overwritten afterwards — these accumulate project content.
SEEDED=(CLAUDE.md README.md settings.json project.conf comment_style.md
        work/decisions.md work/issues.md work/hotfixes.md work/traps.md work/traps_retired.md
        work/collab.md work/collab_settled.md work/deferred.md work/pipeline_backlog.md
        work/owners.txt)

# Copied only when asked for. The meeting loop presumes more than one person and a regular sitting;
# three commands a solo user will never run are three commands in the way.
OPTIONAL_SKILLS=(make-agenda start-meeting end-meeting)

die() { echo "error: $*" >&2; exit 1; }

MODE=install
WITH_MEETINGS=0
args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --promote) MODE=promote ;;
        --update)  MODE=update ;;
        --export)  MODE=export ;;
        --diff)    MODE=diff ;;
        --with-meetings) WITH_MEETINGS=1 ;;
        -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        -*) die "unknown flag: $1" ;;
        *) args+=("$1") ;;
    esac
    shift
done
[[ ${#args[@]} -gt 0 ]] || args=("")

case "$MODE" in

promote)
    # Run inside a fresh fork of this template. The fork arrives shaped like the TEMPLATE — a
    # template/ directory plus this installer — and needs to be shaped like a .claude/ instead.
    TARGET="${args[0]:-$TEMPLATE_DIR}"
    TARGET="$(cd "$TARGET" && pwd)"
    [[ -d "$TARGET/template" ]] || die "no template/ in $TARGET — is this a fork of claude-template?"
    [[ -d "$TARGET/.git" ]] || die "not a git repository: $TARGET — fork it on your host first, then clone it"

    origin="$(git -C "$TARGET" remote get-url origin 2>/dev/null || echo '')"
    case "$origin" in
        *claude-template*)
            die "origin still points at the template itself ($origin).
       Fork it on your host first — GitHub 'Use this template' or 'Fork', GitLab 'Fork' — then
       clone YOUR fork and run --promote there. Promoting the template in place would push a
       project's working docs into the shared template's history." ;;
    esac

    echo "promoting $TARGET into a working-docs repository"

    # Remove the template's OWN scaffolding first. Doing it afterwards leaves the template's root
    # README.md shadowing the one being promoted out of template/, so that file never moves and
    # template/ is left behind non-empty.
    for f in install.sh README.md; do
        [[ -e "$TARGET/$f" ]] || continue
        git -C "$TARGET" rm -q -f "$f" 2>/dev/null || rm -f "$TARGET/$f"
        echo "  remove   $f (template scaffolding)"
    done

    shopt -s dotglob
    for item in "$TARGET"/template/*; do
        name="$(basename "$item")"
        [[ -e "$TARGET/$name" ]] && { echo "  skip     $name (already at the root)"; continue; }
        git -C "$TARGET" mv "template/$name" "$name" 2>/dev/null || mv "$item" "$TARGET/$name"
        echo "  promote  $name"
    done
    shopt -u dotglob
    if ! rmdir "$TARGET/template" 2>/dev/null; then
        echo "  NOTE     template/ is not empty — left in place, inspect it:"
        find "$TARGET/template" -mindepth 1 -maxdepth 2 | sed "s|$TARGET/|           |"
    fi

    mkdir -p "$TARGET"/work/{archive,meetings} "$TARGET"/checks
    [[ -e "$TARGET/.gitignore" ]] || printf 'settings.local.json\nworktrees/\n' > "$TARGET/.gitignore"
    [[ -e "$TARGET/settings.local.json" ]] || echo '{}' > "$TARGET/settings.local.json"
    chmod +x "$TARGET"/hooks/*.sh "$TARGET"/checks/*.sh "$TARGET"/codex/*.sh 2>/dev/null || true

    cat <<EOF

Promoted. This repository is now a .claude/ rather than a template.

Next:

    cd $TARGET
    git add -A && git commit -m "Promote the template into this project's working docs"
    git push

Then, inside the project it belongs to:

    git clone <this repo's URL> .claude
    echo '.claude/' >> .gitignore        # the project must not track it as well

Then open Claude Code there and run /setup. It fills in project.conf and CLAUDE.md.

Keeping up with the template later — this is what the fork buys you:

    git remote add upstream <this template's URL>    # once
    git fetch upstream && git merge upstream/main    # when you want its improvements

and to send an improvement back, push a branch here and open a pull request against upstream.
EOF
    ;;

install)
    TARGET_PROJECT="${args[0]}"
    [[ -n "$TARGET_PROJECT" ]] || die "no project directory given"
    [[ -d "$TARGET_PROJECT" ]] || die "not a directory: $TARGET_PROJECT"
    TARGET_PROJECT="$(cd "$TARGET_PROJECT" && pwd)"
    DEST="$TARGET_PROJECT/.claude"

    [[ -d "$DEST/.git" ]] && die "$DEST is a clone (fork layout) — pull it instead of installing over it"

    echo "installing .claude/ into $TARGET_PROJECT  (copy layout)"
    mkdir -p "$DEST"/work/{current,parked,archive,meetings,reference} "$DEST"/{skills,hooks,checks,output-styles,codex}

    skipped=0 written=0
    for f in "${SEEDED[@]}"; do
        if [[ -e "$DEST/$f" ]]; then
            echo "  skip     $f (already exists)"; skipped=$((skipped + 1))
        else
            mkdir -p "$(dirname "$DEST/$f")"
            cp "$SRC/$f" "$DEST/$f"; echo "  write    $f"; written=$((written + 1))
        fi
    done

    for d in "${MACHINERY_DIRS[@]}"; do
        [[ -d "$SRC/$d" ]] || continue
        mkdir -p "$DEST/$d"
        cp -r "$SRC/$d/." "$DEST/$d/"
        chmod +x "$DEST/$d"/*.sh 2>/dev/null || true
        echo "  write    $d/"
    done

    if [[ "$WITH_MEETINGS" -eq 1 ]]; then
        for s in "${OPTIONAL_SKILLS[@]}"; do
            cp -r "$SRC/skills-optional/$s" "$DEST/skills/$s"
            echo "  write    skills/$s/  (optional)"
        done
    fi

    [[ -e "$DEST/settings.local.json" ]] || echo '{}' > "$DEST/settings.local.json"
    cp "$SRC/work/meetings/README.md" "$DEST/work/meetings/" 2>/dev/null || true

    echo
    echo "wrote $written, skipped $skipped."
    if [[ -d "$TARGET_PROJECT/.git" ]] && git -C "$TARGET_PROJECT" check-ignore -q .claude 2>/dev/null; then
        cat <<'WARN'

⚠  .claude/ is gitignored in this project.

   On the COPY layout that is the single biggest fragility in the system: CLAUDE.md, the skills,
   hotfixes.md and decisions.md then have no version control and no recovery path, and teammates
   never see them.

   Recommended .gitignore instead — track the machinery, ignore only what is personal:

       .claude/settings.local.json

   work/archive/ is deliberately NOT ignored: a finished task's record is shared history, and
   ignoring it strands every /done on one laptop. Whether to ignore the LIVE task directory
   depends on project.conf — /setup settles it.

   If you would rather not track it at all, use the FORK layout instead (install.sh --promote):
   the docs get their own repository, which is version control without touching this one.
WARN
    fi
    cat <<EOF

Next — open Claude Code in this project and run:

    /setup

It inspects the repo, asks what it cannot infer, fills in project.conf and CLAUDE.md, and wires up
the hooks that apply. Once, ever. Then /start your first task.
EOF
    ;;

update)
    TARGET_PROJECT="${args[0]}"; [[ -d "$TARGET_PROJECT" ]] || die "not a directory: $TARGET_PROJECT"
    DEST="$(cd "$TARGET_PROJECT" && pwd)/.claude"
    [[ -d "$DEST" ]] || die "no .claude/ in $TARGET_PROJECT — run install first"
    [[ -d "$DEST/.git" ]] && die "$DEST is a clone (fork layout) — use: git -C $DEST pull"
    echo "refreshing machinery in $DEST (all project content left alone)"
    for d in "${MACHINERY_DIRS[@]}"; do
        [[ -d "$SRC/$d" ]] || continue
        cp -r "$SRC/$d/." "$DEST/$d/"
        chmod +x "$DEST/$d"/*.sh 2>/dev/null || true
        echo "  update   $d/"
    done
    echo "done. Project content untouched: ${SEEDED[*]}"
    ;;

export)
    TARGET_PROJECT="${args[0]}"; [[ -d "$TARGET_PROJECT" ]] || die "not a directory: $TARGET_PROJECT"
    DEST="$(cd "$TARGET_PROJECT" && pwd)/.claude"
    [[ -d "$DEST" ]] || die "no .claude/ in $TARGET_PROJECT"
    if [[ -d "$DEST/.git" ]]; then
        cat >&2 <<EOF
$DEST is a clone (fork layout), so --export is the wrong tool: push a branch there and open a pull
request against this template's upstream instead. That keeps authorship and review, which copying
files over the top does not.
EOF
        exit 1
    fi
    echo "pulling machinery from $DEST back into the template"
    for d in "${MACHINERY_DIRS[@]}"; do
        [[ -d "$DEST/$d" ]] && { cp -r "$DEST/$d/." "$SRC/$d/"; echo "  export   $d/"; }
    done
    echo
    echo "Review and commit in the template repo:"
    echo "  cd $TEMPLATE_DIR && git diff && git commit -am 'skills: <what changed>'"
    ;;

diff)
    TARGET_PROJECT="${args[0]}"; [[ -d "$TARGET_PROJECT" ]] || die "not a directory: $TARGET_PROJECT"
    DEST="$(cd "$TARGET_PROJECT" && pwd)/.claude"
    [[ -d "$DEST" ]] || die "no .claude/ in $TARGET_PROJECT"
    for d in "${MACHINERY_DIRS[@]}"; do
        [[ -d "$SRC/$d" ]] || continue
        diff -ru "$SRC/$d" "$DEST/$d" || true
    done
    ;;
esac
