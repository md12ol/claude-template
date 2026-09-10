#!/usr/bin/env bash
# Is this machine set up to work on this project? One PASS/FAIL line per criterion.
# Exits non-zero if any line FAILs, so it can gate a cold-session test.
#
#     .claude/checks/cloud_ready.sh
#
# READ-ONLY. It builds nothing, installs nothing and writes nothing, which is why it has no
# CLAUDE_CODE_REMOTE guard the way cloud_setup.sh does: it is safe on a laptop and useful there.
# If a line FAILs, the fix is cloud_setup.sh or an edit to project.conf, never this script.
set -uo pipefail

# shellcheck source=../hooks/lib.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/lib.sh"
claude_paths
load_conf
cd "$PROJECT_DIR" || { echo "FAIL  cannot enter $PROJECT_DIR"; exit 1; }
fails=0

check() {  # check <label> <command...>
  local label="$1"; shift
  local out
  if out="$("$@" 2>&1)"; then
    printf 'PASS  %-30s %s\n' "$label" "$(head -1 <<<"$out")"
  else
    printf 'FAIL  %-30s %s\n' "$label" "$(head -1 <<<"$out")"
    fails=$((fails + 1))
  fi
}

identity() {
  resolve_owner
  if is_shared; then
    [[ -n "$OWNER_DIR" ]] || { echo "unrecognised: ${OWNER_EMAIL:-unset} — add it to work/owners.txt"; return 1; }
    echo "${OWNER_NAME:-$OWNER_DIR} (${OWNER_EMAIL})"
  else
    [[ -n "$OWNER_EMAIL" ]] || { echo "git user.email is unset"; return 1; }
    echo "$OWNER_EMAIL"
  fi
}

claude_complete() {
  local missing=""
  for d in skills hooks work; do [[ -d "$CLAUDE_DIR/$d" ]] || missing="$missing $d"; done
  [[ -z "$missing" ]] || { echo "missing:$missing — $(clone_hint)"; return 1; }
  echo "skills, hooks and work present"
}

hooks_runnable() {
  local bad=""
  for h in "$CLAUDE_DIR"/hooks/*.sh; do
    [[ -f "$h" ]] || continue
    bash -n "$h" 2>/dev/null || bad="$bad $(basename "$h")"
  done
  [[ -z "$bad" ]] || { echo "syntax errors in:$bad"; return 1; }
  echo "$(find "$CLAUDE_DIR/hooks" -name '*.sh' | wc -l | tr -d ' ') scripts parse"
}

# CRLF is the failure that looks like a missing file: a shebang naming `bash\r`, which does not
# exist. gitattributes.shared prevents it; this catches a checkout made before that landed.
no_crlf() {
  local bad
  bad="$(grep -rlU $'\r' "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/checks" 2>/dev/null | head -3)"
  [[ -z "$bad" ]] || { echo "CRLF line endings in: $bad"; return 1; }
  echo "all LF"
}

docs_clean() {
  [[ -d "$CLAUDE_DIR/.git" ]] || { echo ".claude/ is not a clone — it should be"; return 1; }
  local dirty
  dirty="$(git -C "$CLAUDE_DIR" status --porcelain | wc -l | tr -d ' ')"
  echo "$(git -C "$CLAUDE_DIR" rev-parse --short HEAD), $dirty uncommitted"
}

tracker() {
  case "$TRACKER_CLI" in
    none|"") echo "none configured (project.conf)"; return 0 ;;
    *) command -v "$TRACKER_CLI" >/dev/null || { echo "$TRACKER_CLI not on PATH"; return 1; }
       echo "$($TRACKER_CLI --version 2>&1 | head -1)" ;;
  esac
}

echo "cloud_ready: $PROJECT_NAME  (people=$PEOPLE machines=$MACHINES host=$HOST)"
check "git identity"        identity
check ".claude complete"    claude_complete
check "hook scripts parse"  hooks_runnable
check "line endings"        no_crlf
check "working docs"        docs_clean
check "tracker CLI"         tracker

# <!-- FILL IN — project-specific readiness checks.
#
# The things that must work before the first task is worth starting: a build, a test run, a
# formatter, a required service. One check() line each, each returning non-zero on failure.
#
#   check "build"  <your build command>
#   check "tests"  <your fast test command>
# -->

[[ $fails -eq 0 ]] && echo "cloud_ready: all checks passed" || echo "cloud_ready: $fails FAILED"
exit "$fails"
