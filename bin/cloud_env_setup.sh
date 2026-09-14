#!/usr/bin/env bash
# The reviewed half of a cloud environment's setup script. A hosted environment can run a script
# before the session starts, configured in a web form rather than in either repository: nobody
# reviews it, nothing version-controls it, and recreating the environment loses it.
#
# So the form holds two lines and nothing else, and everything that could ever need changing lives
# here, where it goes through review like any other script. The clone line cannot live here for the
# obvious reason, and it is the one line that has to be duplicated:
#
#     [ -d .claude/skills ] || git clone --quiet <DOCS_REPO_URL> .claude
#     exec .claude/bin/cloud_env_setup.sh <owner-dir>
#
#     .claude/bin/cloud_env_setup.sh <owner-dir>
#
# Each person's environment names their OWN owner directory. Copying someone else's to get past a
# stop writes into their work/ directory, silently: an unknown one exits 2 rather than guessing.
#
# Test:  .claude/bin/cloud_env_setup.sh nobody   # exits 2 on a shared install

set -uo pipefail

# shellcheck source=../hooks/lib.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/lib.sh"
claude_paths
load_conf

owner="${1:-}"
if is_shared; then
    table="$CLAUDE_DIR/work/owners.txt"
    known="$(awk '!/^[[:space:]]*#/ && NF {gsub(/\t/, " "); print $2}' "$table" 2>/dev/null | sort -u | tr '\n' ' ')"
    if [[ -z "$owner" ]] || ! grep -qwF -- "$owner" <<<"$known"; then
        echo "cloud_env_setup: name your own owner directory, not the other person's." >&2
        echo "  Known: ${known:-none; work/owners.txt is missing}" >&2
        echo "  The environment's setup script should end: exec .claude/bin/cloud_env_setup.sh <owner-dir>" >&2
        exit 2
    fi
fi

cd "$PROJECT_DIR" || { echo "cloud_env_setup: cannot enter $PROJECT_DIR" >&2; exit 1; }

# cloud_setup.sh refuses to touch the global git config unless this says it is in a container, which
# is the guard that stops it wrecking a laptop. A setup script runs BEFORE the session, so the
# variable the session would carry is not set yet, and this file only ever runs in a container.
export CLAUDE_CODE_REMOTE=true

# A warm container has a docs clone from an earlier session, possibly behind. Fast-forward it before
# anything reads a skill out of it, on DOCS_BRANCH only, and never fatally: a setup script that
# aborts here leaves the session with no conventions at all, which is worse than slightly stale ones.
if [[ "$(git -C "$CLAUDE_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)" == "$DOCS_BRANCH" ]]; then
    git -C "$CLAUDE_DIR" pull --quiet --ff-only origin "$DOCS_BRANCH" 2>/dev/null \
        || echo "  cloud_env_setup: could not fast-forward .claude, continuing on what is there"
fi

"$CLAUDE_DIR/bin/cloud_setup.sh" ${owner:+"$owner"}

# Report rather than gate. A failing check should be visible in the setup log without stopping the
# session from starting: the session can run cloud_ready.sh itself and see the same lines.
"$CLAUDE_DIR/bin/cloud_ready.sh" || echo "  cloud_env_setup: some checks FAILED, see above"
exit 0
