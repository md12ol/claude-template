#!/usr/bin/env bash
# SessionStart — bring the working docs up to date before anything reads them, and fast-forward the
# code repo's default branch when that is what is checked out.
#
# Only ever fast-forwards. Where either repo can't — local commits not pushed, or a working-tree
# change the remote's version would overwrite — it prints one line and leaves everything untouched.
# It never merges, rebases, stashes or discards, so `git status` after it shows what it showed
# before, except on the clean fast-forward path.
#
# Wired only when project.conf says MACHINES="multi". The failure it prevents is a stale doc, which
# needs two MACHINES, not two people: a laptop and a desktop, or any cloud container. On a
# single-machine install nothing can go stale and the network call is pure cost.
#
# Test:  .claude/hooks/pull_main.sh

set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
claude_paths
load_conf

# --- the working docs, always --------------------------------------------------------------------
# Pulled unconditionally when .claude/ is its own clone: it is always on its own branch and never on
# a feature branch, so there is no "am I mid-task" question to ask about it.
ff() {  # ff <label> <repo-dir> <branch>
    local label="$1" dir="$2" branch="$3" l r
    git -C "$dir" fetch origin "$branch" --quiet 2>/dev/null || {
        echo "pull_main: couldn't reach $label's origin, skipping"; return 0
    }
    l="$(git -C "$dir" rev-parse HEAD 2>/dev/null)"
    r="$(git -C "$dir" rev-parse "origin/$branch" 2>/dev/null)"
    [[ -n "$l" && -n "$r" && "$l" != "$r" ]] || return 0

    if git -C "$dir" merge-base --is-ancestor HEAD "origin/$branch" 2>/dev/null; then
        if git -C "$dir" merge --ff-only "origin/$branch" --quiet 2>/dev/null; then
            echo "pull_main: $label fast-forwarded to $(git -C "$dir" rev-parse --short HEAD)"
        else
            echo "pull_main: $label is behind but the fast-forward failed (local changes in the way) — pull by hand"
        fi
    else
        echo "pull_main: $label has commits origin doesn't — push or resolve by hand"
    fi
}

if [[ -d "$CLAUDE_DIR/.git" ]]; then
    ff ".claude" "$CLAUDE_DIR" "$DOCS_BRANCH"
else
    # .claude/ should always be a clone. Someone copied it instead. Say so rather than failing
    # silently — the session brief's setup guard reports the same condition in more detail.
    echo "pull_main: .claude/ is not a clone — see .claude/README.md"
fi

# --- the code repo, only on its default branch ---------------------------------------------------
# A feature branch mid-task is left alone. The default branch is read from the remote rather than
# assumed to be "main": plenty of repos still use "master", and some use something else entirely.
cd "$PROJECT_DIR" || exit 0
[[ -d "$PROJECT_DIR/.git" ]] || exit 0

default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
[[ -n "$default_branch" ]] || default_branch="$(git config --get init.defaultBranch 2>/dev/null)"
[[ -n "$default_branch" ]] || default_branch="main"

branch="$(git branch --show-current 2>/dev/null)"
[[ "$branch" == "$default_branch" ]] || exit 0

ff "$default_branch" "$PROJECT_DIR" "$default_branch"

exit 0
