#!/usr/bin/env bash
# Apply project.conf to the tree: the file moves and edits /setup would otherwise do by hand.
# /setup runs it AFTER writing project.conf and editing CLAUDE.md, and asks nothing: the answers
# are already in project.conf, and the commit is /setup's.
#
#     .claude/bin/setup_apply.sh [--dry-run]
#
# One report line per step: the project's .gitignore, its root CLAUDE.md, the solo removals or the
# union merge driver, the tracker-first removals, the GitHub extra, and the executable bits. Safe to
# re-run.
#
# Test:  .claude/bin/setup_apply.sh --dry-run

set -uo pipefail

# shellcheck source=../hooks/lib.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/lib.sh"
claude_paths; load_conf

DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1
say() { printf '  %s\n' "$*"; }
would() { [[ $DRY -eq 1 ]] && { say "would $*"; return 0; }; return 1; }

cd "$CLAUDE_DIR" || die "setup_apply: cannot enter $CLAUDE_DIR"

# 1. .claude/ is a clone with somewhere to push. /save pushes the live task directory, and that push
#    is the whole reason the directory is tracked; a clone with no origin fails at exactly the
#    moment the work matters.
[[ -d .git ]] || die "setup_apply: .claude/ is not a git clone; it must be one"
git remote 2>/dev/null | grep -qx origin || die "setup_apply: .claude/ has no origin; /save would have nowhere to push"

# 2. The project must ignore .claude/, or every commit touches two repositories. Run with .claude/
#    present: a trailing-slash pattern only matches a directory that exists.
cd "$PROJECT_DIR" || die "setup_apply: cannot enter $PROJECT_DIR"
if git check-ignore -q .claude 2>/dev/null; then
    say ".gitignore: .claude/ is already ignored"
elif ! would "add .claude/ to $PROJECT_DIR/.gitignore"; then
    printf '\n# Working docs: their own repository, cloned into place.\n.claude/\n' >> .gitignore
    say ".gitignore: added .claude/"
fi

# 3. The project's root CLAUDE.md: the only file that still loads when .claude/ is missing
#    entirely, which is the one failure no hook can report.
ex="$CLAUDE_DIR/root_CLAUDE.md.example"
gen() { sed -e "s|<PROJECT>|$PROJECT_NAME|" -e "s|<DOCS_REPO_URL>|$DOCS_REPO_URL|" "$ex" \
        | awk 'drop && /^-->$/ {drop=0; next} !drop' drop=1; }
if [[ ! -f "$ex" ]]; then
    say "root CLAUDE.md: root_CLAUDE.md.example is missing; nothing written"
elif [[ -f CLAUDE.md ]]; then
    say "root CLAUDE.md: already exists and was NOT touched; add this pointer block by hand:"
    gen
elif ! would "write $PROJECT_DIR/CLAUDE.md from root_CLAUDE.md.example"; then
    gen > CLAUDE.md
    say "root CLAUDE.md: written for $PROJECT_NAME"
fi

# 4. The team-shape switch.
cd "$CLAUDE_DIR" || die "setup_apply: cannot enter $CLAUDE_DIR"
if is_shared; then
    if ! would "install gitattributes.multi-writer as .claude/.gitattributes"; then
        cp gitattributes.multi-writer .gitattributes || die "setup_apply: gitattributes.multi-writer is missing"
        # Verify, because getting this wrong is silent: git reads .gitattributes only from the
        # repository containing the file, and union merge never reports a conflict.
        got="$(git check-attr merge -- work/decisions.md work/traps.md | sed 's/.*: //' | tr '\n' ' ')"
        [[ "$got" == "union unspecified " ]] || die "setup_apply: the merge driver did not take (got: $got)"
        say "shared: union merge driver installed and verified"
    fi
else
    # Rules for a hazard that cannot occur teach everyone to skim rules. Restorable by
    # /add-person from this removal's own commit, which is why it is a removal and not a delete.
    gone=()
    for p in work/collab.md work/collab_settled.md work/owners.txt \
             gitattributes.multi-writer skills-optional work/meetings; do
        [[ -e "$p" ]] && gone+=("$p")
    done
    if [[ ${#gone[@]} -eq 0 ]]; then
        say "solo: nothing left to remove"
    elif ! would "git rm -qrf ${gone[*]}"; then
        # -f because /setup may have edited one of these; plain `git rm` refuses on a modified file
        # and the removal then silently does not happen.
        git rm -qrf "${gone[@]}" || die "setup_apply: the solo removal failed; resolve by hand"
        say "solo: removed ${gone[*]}"
    fi
fi

# 5. Tracker-first: the three churn files have no job left. A finding is an issue, and temporary
#    code is a marker at the site plus the issue that removes it. Removed rather than deleted, so
#    the commit /setup makes is the way back.
if is_tracker_first; then
    gone=()
    for p in work/issues.md work/hotfixes.md work/deferred.md; do
        [[ -e "$p" ]] && gone+=("$p")
    done
    if [[ ${#gone[@]} -eq 0 ]]; then
        say "tracker-first: nothing left to remove"
    elif ! would "git rm -qrf ${gone[*]}"; then
        git rm -qrf "${gone[@]}" || die "setup_apply: the tracker-first removal failed; resolve by hand"
        say "tracker-first: removed ${gone[*]}"
    fi
fi

# 6. The one host-specific extra, and only where it can run: assigning the other owner needs both a
#    host that runs workflows and a second person to assign to.
if [[ "$HOST" == "github" ]] && is_shared; then
    if ! would "install .github/workflows/assign-owner.yml from optional/github/"; then
        install_gh_workflow | sed 's/^/  /'
    fi
fi

# 7. A checkout that lost the executable bit turns every hook into a silent no-op, which looks
#    exactly like a hook that decided not to fire.
if ! would "chmod +x bin/*.sh hooks/*.sh"; then
    chmod +x bin/*.sh hooks/*.sh 2>/dev/null
    say "executable: bin/ and hooks/"
fi

[[ $DRY -eq 1 ]] && say "--dry-run: nothing was changed"
exit 0
