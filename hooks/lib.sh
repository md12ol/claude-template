#!/usr/bin/env bash
# Shared helpers for every hook and check. Source it; do not run it.
#
#     . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
# One place reads project identity, the owner table and the solo/shared switches. Everything here is
# defensive: a hook that dies takes the session start with it, so every function degrades to a
# usable default rather than failing.
#
# Test:  bash -c '. .claude/hooks/lib.sh && claude_paths && echo "$CLAUDE_DIR / $OWNER_DIR"'

# --- paths ---------------------------------------------------------------------------------------
# Resolved from this script's own path, never from the working directory. `git rev-parse` cannot be
# used: .claude/ is its own repository, so running from inside it reports .claude as the top level
# and every path below would gain an extra .claude/.
claude_paths() {
    CLAUDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    PROJECT_DIR="$(dirname "$CLAUDE_DIR")"
    export CLAUDE_DIR PROJECT_DIR
}

# --- project.conf --------------------------------------------------------------------------------
# Sourced in a subshell-safe way: unknown keys are ignored, and every value has a default here so a
# missing or half-written project.conf never leaves a variable unset under `set -u`.
load_conf() {
    [[ -n "${CLAUDE_DIR:-}" ]] || claude_paths

    PROJECT_NAME="$(basename "$PROJECT_DIR")"
    DOCS_REPO_NAME=".claude"
    DOCS_REPO_URL=""
    DOCS_BRANCH="main"
    HOST="other"
    TRACKER_CLI="none"
    TRACKER_REPO=""
    PEOPLE="solo"
    MACHINES="single"

    if [[ -f "$CLAUDE_DIR/project.conf" ]]; then
        # shellcheck disable=SC1091
        . "$CLAUDE_DIR/project.conf" 2>/dev/null || true
    fi

    export PROJECT_NAME DOCS_REPO_NAME DOCS_REPO_URL DOCS_BRANCH \
           HOST TRACKER_CLI TRACKER_REPO PEOPLE MACHINES
}

is_shared() { [[ "${PEOPLE:-solo}" == "shared" ]]; }
is_multi_machine() { [[ "${MACHINES:-single}" == "multi" ]]; }

# The command to hand someone whose .claude/ is missing or incomplete. Falls back to naming the
# file to read rather than inventing a URL, because a wrong clone command is worse than none.
clone_hint() {
    if [[ -n "${DOCS_REPO_URL:-}" ]]; then
        echo "git clone $DOCS_REPO_URL .claude"
    else
        echo "see .claude/project.conf (DOCS_REPO_URL) for this project's working-docs repo"
    fi
}

# --- owners --------------------------------------------------------------------------------------
# THE owner table lives in work/owners.txt and nowhere else. Resolves the git identity to a
# directory name, and sets:
#
#   OWNER_DIR    directory name, or "" when unresolved
#   OWNER_NAME   display name, or ""
#   OWNER_EMAIL  the address that was looked up
#   WORK_CURRENT path to the live task dir, relative to CLAUDE_DIR
#   WORK_PARKED  path to the parked task dir, relative to CLAUDE_DIR
#
# On a solo install there is no table and no owner in the path — the whole difference, handled here
# so no caller has to branch on it.
resolve_owner() {
    [[ -n "${CLAUDE_DIR:-}" ]] || claude_paths
    [[ -n "${PEOPLE:-}" ]] || load_conf

    OWNER_EMAIL="$(git -C "$PROJECT_DIR" config user.email 2>/dev/null || true)"
    OWNER_DIR=""
    OWNER_NAME=""

    if ! is_shared; then
        WORK_CURRENT="work/current"
        WORK_PARKED="work/parked"
        export OWNER_DIR OWNER_NAME OWNER_EMAIL WORK_CURRENT WORK_PARKED
        return 0
    fi

    local table="$CLAUDE_DIR/work/owners.txt"
    if [[ -f "$table" && -n "$OWNER_EMAIL" ]]; then
        # Fields split on tabs OR runs of spaces, so a hand-edited table with spaces still works.
        # Only the first two fields are structural; everything after is the display name.
        local line
        line="$(awk -v e="$OWNER_EMAIL" '
            /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
            { gsub(/\t/, " "); }
            $1 == e { $1=""; sub(/^ +/, ""); print; exit }
        ' "$table")"
        if [[ -n "$line" ]]; then
            OWNER_DIR="${line%% *}"
            OWNER_NAME="${line#* }"
            [[ "$OWNER_NAME" == "$OWNER_DIR" ]] && OWNER_NAME=""
        fi
    fi

    if [[ -n "$OWNER_DIR" ]]; then
        WORK_CURRENT="work/$OWNER_DIR/current"
        WORK_PARKED="work/$OWNER_DIR/parked"
    else
        WORK_CURRENT=""
        WORK_PARKED=""
    fi
    export OWNER_DIR OWNER_NAME OWNER_EMAIL WORK_CURRENT WORK_PARKED
}

# Every person in the table but the current one, as "dir<TAB>name" lines. Reports other owners'
# parked work without hardcoding how many people there are — two is not special.
other_owners() {
    [[ -n "${CLAUDE_DIR:-}" ]] || claude_paths
    is_shared || return 0
    local table="$CLAUDE_DIR/work/owners.txt"
    [[ -f "$table" ]] || return 0
    awk -v me="${OWNER_DIR:-}" '
        /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
        { gsub(/\t/, " "); }
        {
            dir = $2
            if (dir == "" || dir == me || seen[dir]++) next
            name = ""
            for (i = 3; i <= NF; i++) name = name (i > 3 ? " " : "") $i
            print dir "\t" (name == "" ? dir : name)
        }
    ' "$table"
}

# --- helpers for bin/ ------------------------------------------------------------------------------
# Only bin/ scripts call these. A hook that exits non-zero can take the session start with it, so
# `die` deliberately has no caller among the hooks.

die() { printf '%s\n' "$*" >&2; exit 1; }

# Stop rather than guess when a shared install does not recognise this address. Writing into someone
# else's work/ directory is silent, and surfaces only when they open a directory they did not expect
# to have work in.
require_owner() {
    [[ -n "${WORK_CURRENT+x}" ]] || resolve_owner
    [[ -n "$WORK_CURRENT" ]] && return 0
    die "unknown git user.email '${OWNER_EMAIL:-unset}' — add it to work/owners.txt; never guess"
}

# handoff.md's stamp: which machine wrote the save, when, and the CODE repo's HEAD at the time.
# Silent on a single-machine install, where the line carries no information.
machine_stamp() {
    is_multi_machine || return 0
    local host sha
    host="$(hostname -s 2>/dev/null || uname -n 2>/dev/null || echo unknown)"
    sha="$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    printf '**Machine:** %s · saved %s · %s\n' "$host" "$(date '+%Y-%m-%d %H:%M')" "$sha"
}
