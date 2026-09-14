#!/usr/bin/env bash
# The task lifecycle as commands rather than prose. /start, /save, /load, /park and /done call
# these; a person can run any of them by hand. Run from the project root or anywhere inside it.
#
#     paths                    OWNER_DIR/WORK_*/the switches and tracker keys, eval-able
#     pull                     fast-forward the docs clone, never the code repo
#     start "<objective>"      list parked tasks, then create the live task dir and seed history.md
#     park|unpark <slug>       move the task out of and back into the live dir
#     archive <slug>           move it to work/archive/<YYYY-MM>_<slug>/
#     stamp | check-stamp      handoff.md's Machine: line; is it still true here?
#     audit [file…]            union-merge collision and structure audit, plus the collab reports
#     collab-next              the next free collab item number
#     temporary                every TEMPORARY ( marker in the CODE repo
#     commit "<message>"       commit the whole docs repo, and push if there is an origin
#     branch-done <branch>     delete a merged feature branch in the CODE repo, local and remote
#
# `commit` stages everything in .claude/ because the docs repo holds no code: there is nothing here
# a person could push by accident. The code repository is never staged, committed or pushed.
#
# A refusal is one line on stderr and exit 1; nothing is half-done. Never `--force`, never a merge.
#
# Test:  .claude/bin/task.sh paths && .claude/bin/task.sh audit

set -uo pipefail

# shellcheck source=../hooks/lib.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/lib.sh"
claude_paths; load_conf; resolve_owner; require_owner
cd "$CLAUDE_DIR" || die "task.sh: cannot enter $CLAUDE_DIR"

has_origin() { git remote 2>/dev/null | grep -qx origin; }
slug_ok() { [[ "$1" =~ ^[a-z0-9-]+$ ]] || die "task.sh: '$1' is not a slug: lowercase letters, digits and hyphens only"; }
nonempty() { [[ -n "$(ls -A "$1" 2>/dev/null)" ]]; }

# One line per parked task, blocker included. `start` prints it first because resuming one is often
# the better session, and a parked task is invisible from the live directory.
parked_lines() {
    [[ -n "$WORK_PARKED" && -d "$WORK_PARKED" ]] || return 0
    local dir slug blocked
    for dir in "$WORK_PARKED"/*/; do
        [[ -d "$dir" ]] || continue
        slug="$(basename "$dir")"
        blocked="$(grep -m1 -o '\*\*Blocked on:\*\*.*' "$dir/handoff.md" 2>/dev/null | sed 's/\*\*Blocked on:\*\* *//')"
        printf 'parked: %s  %s\n' "$slug" "${blocked:-no blocker recorded}"
    done
}

cmd="${1:-}"; shift 2>/dev/null || true

case "$cmd" in

paths)
    printf 'OWNER_DIR=%q\nWORK_CURRENT=%q\nWORK_PARKED=%q\nPEOPLE=%q\nMACHINES=%q\n' \
        "$OWNER_DIR" "$WORK_CURRENT" "$WORK_PARKED" "$PEOPLE" "$MACHINES"
    printf 'TRACKER_CLI=%q\nTRACKER_REPO=%q\nTRACKER_FIRST=%q\nNEEDS_RULING_LABEL=%q\n' \
        "$TRACKER_CLI" "$TRACKER_REPO" "$TRACKER_FIRST" "$NEEDS_RULING_LABEL"
    printf 'BRANCH_PATTERN=%q\nLABELS_DERIVED=%q\nKIND_LABELS=%q\n' \
        "$BRANCH_PATTERN" "$LABELS_DERIVED" "$KIND_LABELS"
    ;;

# Never blocks a session: a clone with no origin, or an unreachable one, is reported and tolerated.
pull)
    has_origin || exit 0
    git pull --ff-only --quiet 2>/dev/null || echo "task.sh pull: .claude/ did not fast-forward; pull it by hand"
    exit 0
    ;;

start)
    obj="${1:-}"
    [[ -n "$obj" ]] || die "task.sh start: needs the objective in one line"
    parked_lines
    if nonempty "$WORK_CURRENT"; then
        die "task.sh start: $WORK_CURRENT is not empty ($(ls -A "$WORK_CURRENT" | tr '\n' ' ')); /done or /park it first"
    fi
    mkdir -p "$WORK_CURRENT" || die "task.sh start: cannot create $WORK_CURRENT"
    if [[ ! -s "$WORK_CURRENT/history.md" ]]; then
        { printf '# History: %s\n\n' "$obj"
          printf 'Append-only session log for this task, newest session first.\n'
          printf 'Maintained by `/save`; archived by `/done`.\n\n---\n'; } > "$WORK_CURRENT/history.md"
    fi
    echo "$WORK_CURRENT"
    ;;

park)
    slug="${1:-}"; [[ -n "$slug" ]] || die "task.sh park: needs a slug"
    slug_ok "$slug"
    [[ -f "$WORK_CURRENT/plan.md" ]] || die "task.sh park: no plan.md in $WORK_CURRENT; nothing to park"
    [[ -e "$WORK_PARKED/$slug" ]] && die "task.sh park: $WORK_PARKED/$slug already exists; pick another slug, never merge two task directories"
    mkdir -p "$WORK_PARKED" || die "task.sh park: cannot create $WORK_PARKED"
    mv "$WORK_CURRENT" "$WORK_PARKED/$slug" || die "task.sh park: the move failed"
    mkdir -p "$WORK_CURRENT"
    [[ -f "$WORK_PARKED/$slug/plan.md" ]] || die "task.sh park: plan.md is not at $WORK_PARKED/$slug/plan.md; the task nested"
    # The handoff now describes a task nobody is holding, so say both things it must say: that this
    # save was a park rather than a stop, and the one command that brings it back.
    h="$WORK_PARKED/$slug/handoff.md"
    if [[ -f "$h" ]]; then
        resume="Resume with \`/load $slug\`."
        after=blocked
        if ! grep -q '^\*\*Blocked on:' "$h"; then
            after=heading
            echo 'park: no Blocked on line; the brief will show "no blocker recorded"' >&2
        fi
        grep -qF "$resume" "$h" && after=none
        awk -v resume="$resume" -v after="$after" '
            !m && /^\*\*Machine:/ { sub(/ · saved /, " · parked "); m = 1 }
            { print }
            !placed && after == "blocked" && /^\*\*Blocked on:/ { print resume; placed = 1 }
            !placed && after == "heading" && /^#/     { print resume; placed = 1 }
        ' "$h" > "$h.new" && mv "$h.new" "$h"
    fi
    echo "$WORK_PARKED/$slug"
    ;;

# The rmdir is the load-bearing step: `mv src dst` onto an EXISTING directory moves src inside it,
# nothing errors, and the task reads as lost because everything looks one level up.
unpark)
    slug="${1:-}"; [[ -n "$slug" ]] || die "task.sh unpark: needs a slug"
    slug_ok "$slug"
    [[ -d "$WORK_PARKED/$slug" ]] || die "task.sh unpark: nothing parked under $WORK_PARKED/$slug"
    nonempty "$WORK_CURRENT" && die "task.sh unpark: $WORK_CURRENT is not empty; park the live task first"
    rmdir "$WORK_CURRENT" 2>/dev/null
    mv "$WORK_PARKED/$slug" "$WORK_CURRENT" || die "task.sh unpark: the move failed"
    [[ -f "$WORK_CURRENT/plan.md" ]] || die "task.sh unpark: plan.md is not at $WORK_CURRENT/plan.md; the task nested"
    echo "$WORK_CURRENT"
    grep -m1 '\*\*Blocked on:\*\*' "$WORK_CURRENT/handoff.md" 2>/dev/null
    exit 0
    ;;

archive)
    slug="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' | tr -cd 'a-z0-9-')"
    [[ -n "$slug" ]] || die "task.sh archive: needs a slug"
    [[ -f "$WORK_CURRENT/plan.md" ]] || die "task.sh archive: no plan.md in $WORK_CURRENT; nothing to archive"
    dest="work/archive/$(date +%Y-%m)_$slug"
    [[ -e "$dest" ]] && die "task.sh archive: $dest exists; pass ${slug}-2, or archive into it by hand"
    mkdir -p "$dest" || die "task.sh archive: cannot create $dest"
    shopt -s dotglob nullglob
    for f in "$WORK_CURRENT"/*; do
        mv "$f" "$dest/" || die "task.sh archive: could not move $f; nothing is deleted, finish by hand"
    done
    shopt -u dotglob nullglob
    echo "$dest"
    ;;

stamp)
    machine_stamp
    ;;

# Answers the one question /load asks before trusting a handoff: was this written here, against a
# tree this machine has? It never merges or resets: two machines editing one plan is a human call.
check-stamp)
    is_multi_machine || exit 0
    line="$(grep -m1 '^\*\*Machine:' "$WORK_CURRENT/handoff.md" 2>/dev/null)"
    [[ -n "$line" ]] || { echo "check-stamp: no stamp; the last save predates the convention"; exit 0; }
    # Tolerant of backticks and of a stamp with no HH:MM; real handoffs have both variants.
    clean="$(printf '%s' "$line" | tr -d '`')"
    host="$(printf '%s' "$clean" | awk -F'·' '{sub(/^\*\*Machine:\*\*[[:space:]]*/, "", $1); gsub(/[[:space:]]+$/, "", $1); print $1}')"
    sha="$(printf '%s' "$clean" | awk -F'·' '{print $NF}' | tr -d '[:space:]')"
    here="$(hostname -s 2>/dev/null || uname -n 2>/dev/null || echo unknown)"
    rc=0
    # Uncommitted docs are the save that never finished. They outrank the handoff, which describes
    # the state the last session MEANT to leave, so say so before anything is trusted.
    n="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    if [[ "${n:-0}" -gt 0 ]]; then
        echo "check-stamp: the docs clone has $n uncommitted change(s): a previous session ended before its save reached the push; they are probably the real state"
        rc=1
    fi
    [[ "$host" == "$here" ]] && echo "check-stamp: same machine ($here)" \
                             || echo "check-stamp: written on $host, you are on $here"
    if git -C "$PROJECT_DIR" merge-base --is-ancestor "$sha" HEAD 2>/dev/null; then
        echo "check-stamp: $sha is in this code repo's history"
    else
        echo "check-stamp: $sha is NOT in this code repo's history; stop, show both sides, never merge or reset"
        rc=1
    fi
    if has_origin; then
        ahead="$(git rev-list --count "origin/$DOCS_BRANCH..HEAD" 2>/dev/null || echo 0)"
        [[ "${ahead:-0}" -gt 0 ]] && { echo "check-stamp: the docs clone has $ahead commit(s) origin lacks; push or resolve by hand"; rc=1; }
    fi
    exit $rc
    ;;

# Union merge never conflicts. Two failures, and `uniq -d` sees only the first: byte-identical
# lines dedupe and interleave two entries; a splice puts one entry's heading mid-line in another.
audit)
    files=(); [[ $# -gt 0 ]] && files=("$@")
    if [[ ${#files[@]} -eq 0 ]]; then
        for f in work/decisions.md work/collab.md work/collab_settled.md; do
            [[ -f "$f" ]] && files+=("$f")
        done
    fi
    rc=0
    for f in "${files[@]}"; do
        [[ -f "$f" ]] || { echo "audit: $f does not exist"; rc=1; continue; }
        dup="$(grep -vE '^[[:space:]]*$' "$f" | sort | uniq -d | head -3)"
        [[ -n "$dup" ]] && { echo "audit: $f has lines two entries could collapse onto: $dup"; rc=1; }
        all="$(grep -c '### [0-9]' "$f" 2>/dev/null | head -1)"
        col0="$(grep -c '^### [0-9]' "$f" 2>/dev/null | head -1)"
        [[ "${all:-0}" -ne "${col0:-0}" ]] && { echo "audit: $f has an item heading mid-line: a splice, not a duplicate"; rc=1; }
    done
    [[ $rc -eq 0 ]] && echo "audit: ${#files[@]} file(s) clean"
    # Two REPORTS, not failures: an unanswered question is somebody's turn, and a settled item with
    # no disposition is a gap only its author can fill. Neither is a collision, so neither is fatal.
    if is_shared; then
        [[ -f work/collab.md ]] && awk '
            /^## Open/      { open = 1; next }
            /^## /          { if (open) { if (h != "") print "unanswered: " h; h = ""; open = 0 } }
            !open           { next }
            /^### [0-9]+\./ { if (h != "") print "unanswered: " h
                              sub(/^### /, "#"); sub(/\. /, " "); h = $0; next }
            /answered/      { h = "" }
            END             { if (h != "") print "unanswered: " h }
        ' work/collab.md
        [[ -f work/collab_settled.md ]] && awk '
            /^### [0-9]+\./ { if (h != "" && !s) print "no disposition: " h; h = $0; s = 0; next }
            /^\*\*(Settled|Closed|Superseded|No disposition|Moved here from Open)/ { s = 1 }
            END             { if (h != "" && !s) print "no disposition: " h }
        ' work/collab_settled.md
    fi
    exit $rc
    ;;

# Item numbers run as ONE sequence across the open file and its archive, so the next free number is
# a question about both. Taking a number already used is the collision union merge cannot show you.
collab-next)
    n=0
    for f in work/collab.md work/collab_settled.md; do
        [[ -f "$f" ]] || continue
        seen=1
        m="$(grep -oE '^### [0-9]+' "$f" | grep -oE '[0-9]+' | sort -n | tail -1)"
        [[ -n "$m" && "$m" -gt "$n" ]] && n="$m"
    done
    [[ -n "${seen:-}" ]] && echo $((n + 1))
    exit 0
    ;;

# The inventory of temporary code. It lives at the sites themselves, so this is the only listing.
temporary)
    git -C "$PROJECT_DIR" grep -n "TEMPORARY (" 2>/dev/null
    exit 0
    ;;

commit)
    msg="${1:-}"
    [[ -n "$msg" ]] || die "task.sh commit: needs a message"
    # The whole docs repo, not just the task directories: it holds no code, so there is nothing here
    # that could be pushed by accident, and a decision or a trap left unstaged is a save that lied.
    git add -A 2>/dev/null
    if git diff --cached --quiet 2>/dev/null; then
        echo "task.sh commit: nothing staged in the docs repo"
        exit 0
    fi
    git commit -q -m "$msg" || die "task.sh commit: the commit failed"
    echo "task.sh commit: $(git rev-parse --short HEAD) $msg"
    has_origin || { echo "task.sh commit: no origin; committed locally only"; exit 0; }
    git push --quiet 2>/dev/null && { echo "task.sh commit: pushed"; exit 0; }
    die "task.sh commit: push rejected; the other machine saved first, do not force"
    ;;

# A merged branch left lying around on two machines is the state nobody can tell from an open one.
# Only ever `-d`: the refusal on an unmerged branch is the whole safety property, so never `-D`.
branch-done)
    br="${1:-}"; [[ -n "$br" ]] || die "task.sh branch-done: needs a branch name"
    cur="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)"
    [[ "$cur" == "$br" ]] && die "task.sh branch-done: $br is checked out; switch off it first"
    git -C "$PROJECT_DIR" fetch --prune --quiet 2>/dev/null
    # Read the default branch the way pull_main.sh does, rather than assuming it is called main.
    def="$(git -C "$PROJECT_DIR" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
    [[ -n "$def" ]] || def="$(git -C "$PROJECT_DIR" config --get init.defaultBranch 2>/dev/null)"
    [[ -n "$def" ]] || def="main"
    git -C "$PROJECT_DIR" rev-parse --verify --quiet "$def" >/dev/null || def="origin/$def"
    if ! git -C "$PROJECT_DIR" branch --merged "$def" 2>/dev/null | sed 's/^[*+ ]*//' | grep -qxF "$br"; then
        echo "branch-done: $br is NOT merged, leaving both copies; its PR is still open"
        exit 1
    fi
    git -C "$PROJECT_DIR" branch -d "$br" >/dev/null 2>&1 \
        || die "task.sh branch-done: could not delete $br locally; finish by hand, never with -D"
    echo "branch-done: deleted $br locally"
    git -C "$PROJECT_DIR" push --quiet origin --delete "$br" 2>/dev/null \
        && echo "branch-done: deleted origin/$br" \
        || echo "branch-done: remote copy already gone"
    exit 0
    ;;

*)
    die "task.sh: unknown command '${cmd:-}'; see the header of $0"
    ;;
esac
