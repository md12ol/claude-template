#!/usr/bin/env bash
# SessionStart — orient even when /load isn't typed.
#
# Prints the handoff's "Start here" plus the counts that go stale silently: unverified [~] items,
# open [ ] items, unfiled issues. It does NOT replace /load, which verifies the handoff against the
# repo. The install's shape comes from project.conf and work/owners.txt, via lib.sh.
#
# Test:  .claude/hooks/session_brief.sh

set -uo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
claude_paths
cd "$CLAUDE_DIR" || exit 0

rule_top="─── .claude ───────────────────────────────────────────────"
rule_bot="───────────────────────────────────────────────────────────"

# --- setup guard ---------------------------------------------------------------------------------
# The PARTIAL case — .claude/ is there but missing the pieces that matter — is the only missing-
# clone case a hook CAN catch: absent entirely, settings.json and this script go with it. The
# project's root CLAUDE.md, the one file that still loads, covers the total case.
if [[ ! -d "$CLAUDE_DIR/skills" || ! -d "$CLAUDE_DIR/work" ]]; then
    load_conf
    echo "$rule_top"
    echo "STOP — .claude/ is incomplete: skills/ or work/ is missing."
    echo "It is a clone of $DOCS_REPO_NAME, not part of this repository."
    echo
    if [[ -n "$DOCS_REPO_URL" ]]; then
        echo "    rm -rf .claude && $(clone_hint)"
    else
        echo "    $(clone_hint)"
    fi
    echo
    echo "Until then no conventions are loaded and nothing in this session is bound by them."
    echo "$rule_bot"
    exit 0
fi

load_conf

# /setup has not run yet if CLAUDE.md still carries its FILL IN blocks; /start would write a plan
# against rules nobody has agreed. Match the em-dash heading every block opens with, never the bare
# words: a project rule that merely quotes them would otherwise read as unconfigured forever.
if grep -q 'FILL IN —' "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; then
    echo "$rule_top"
    echo "This .claude/ has not been configured yet — CLAUDE.md still has FILL IN blocks."
    echo "Run /setup first. It writes project.conf and CLAUDE.md, wires the hooks that apply,"
    echo "and adds .claude/ to this project's .gitignore. Then /start your first task."
    echo "$rule_bot"
    exit 0
fi

resolve_owner

# On a shared install an unrecognised identity is ambiguous, and writing into the wrong person's
# directory is silent. Say so and stop — but exit 0: a hook that blocks a session is worse.
if is_shared && [[ -z "$OWNER_DIR" ]]; then
    echo "$rule_top"
    echo "Unrecognised git user.email (${OWNER_EMAIL:-unset}) — cannot tell whose work/ directory this is."
    echo "Add it to .claude/work/owners.txt (one line, no other file needs editing), then re-run."
    echo "$rule_bot"
    exit 0
fi

# `grep -c` prints its count AND exits 1 when it is zero, so the obvious `|| echo 0` appends a
# SECOND zero and breaks the counts line in two. Take the first line.
count() {  # count <pattern> <file>
    local n
    n=$(grep -c "$1" "$2" 2>/dev/null | head -1)
    echo "${n:-0}"
}

# Parked tasks, with what each is blocked on — the question you actually ask on return.
parked_report() {
    [[ -n "$WORK_PARKED" && -d "$WORK_PARKED" ]] || return 0
    local dir slug blocked
    for dir in "$WORK_PARKED"/*/; do
        [[ -d "$dir" ]] || continue
        slug="$(basename "$dir")"
        blocked="$(grep -m1 -o '\*\*Blocked on:\*\*.*' "$dir/handoff.md" 2>/dev/null | sed 's/\*\*Blocked on:\*\* *//')"
        printf '  parked: %-24s %s\n' "$slug" "${blocked:-no blocker recorded}"
    done
}

# One line per other owner, so their in-flight work is visible without being noise.
others_report() {
    local dir name cur parked
    while IFS=$'\t' read -r dir name; do
        [[ -n "$dir" ]] || continue
        cur=0
        [[ -f "work/$dir/current/plan.md" ]] && cur=1
        parked=0
        [[ -d "work/$dir/parked" ]] && parked=$(find "work/$dir/parked" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        [[ "$cur" -gt 0 || "$parked" -gt 0 ]] && printf '  %s: %s current, %s parked\n' "$name" "$cur" "$parked"
    done < <(other_owners)
}

echo "$rule_top"

if [[ ! -f "$WORK_CURRENT/plan.md" ]]; then
    if [[ -n "$(parked_report)" ]]; then
        echo "No active task in .claude/$WORK_CURRENT/ — these are parked:"
        parked_report
        echo "Resume one with /load <slug>, or start something new with /start."
    else
        echo "No active task in .claude/$WORK_CURRENT/ — start one with /start."
    fi
    others_report
    echo "$rule_bot"
    exit 0
fi

open=$(count '^- \[ \]' "$WORK_CURRENT/plan.md")
unver=$(count '^- \[~\]' "$WORK_CURRENT/plan.md")
unfiled=$(count 'Filed:.*not yet' work/issues.md)
traps=$(count '^### ' work/traps.md)

if [[ -f "$WORK_CURRENT/handoff.md" ]]; then
    sed -n '1p' "$WORK_CURRENT/handoff.md"
    # How a stale cross-machine handoff shows up before you have trusted anything in it.
    is_multi_machine && grep -m1 '^\*\*Machine:' "$WORK_CURRENT/handoff.md"
    # The "Start here" section, up to the next heading or the next bold label. The stop pattern says
    # "** not followed by a lowercase letter" rather than listing the labels that can follow: one of
    # them opens with a multibyte character, and those are undefined in a mawk bracket expression.
    awk '/^(## .*Start here|\*\*Start here)/{f=1; print; next}
         f && (/^## / || (/^\*\*/ && !/^\*\*[a-z]/)){exit}
         f' "$WORK_CURRENT/handoff.md" | head -12
fi

printf '\nopen [ ]: %s   unverified [~]: %s   unfiled issues: %s   traps: %s\n' \
    "$open" "$unver" "$unfiled" "$traps"
parked_report
others_report
echo "Run /load to verify this against the repo before trusting it."
echo "$rule_bot"

exit 0
