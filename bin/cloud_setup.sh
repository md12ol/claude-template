#!/usr/bin/env bash
# Bring a fresh cloud container up to a working machine for this project. Idempotent and
# non-interactive: safe to re-run, never prompts, never writes a secret.
#
#     .claude/bin/cloud_setup.sh [owner-directory]
#
# The owner argument is needed only when git's user.email is not one work/owners.txt knows. It is
# never guessed: on a shared install the wrong identity writes into someone else's work/ directory,
# silently, and surfaces days later.
#
# RE-RUN AFTER A RESUME OR A COMPACT. Containers commonly rewrite their own name and email back
# into ~/.gitconfig, so an identity set at session start does not survive one.
#
# It deliberately installs no toolchain and builds nothing: that differs per project and belongs
# in the FILL IN block at the bottom.
#
# Test:  CLAUDE_CODE_REMOTE= .claude/bin/cloud_setup.sh   # refuses off a container, exit 3
set -euo pipefail

# shellcheck source=../hooks/lib.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/lib.sh"
claude_paths
load_conf

# DESTRUCTIVE anywhere but a throwaway container: it sets the GLOBAL git identity and turns off
# global commit signing, which on a machine you own overrides your identity and silently stops
# signing every repository on it. CLAUDE_CODE_REMOTE is the one reliable way to tell the two apart.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  echo "cloud_setup: this is not a cloud session." >&2
  echo "  It sets your GLOBAL git identity and disables GLOBAL commit signing, which is wrong" >&2
  echo "  for a machine you own. Nothing has been changed." >&2
  echo "  On your own machine you already have an identity and nothing here is needed." >&2
  exit 3
fi

cd "$PROJECT_DIR"
say() { printf '  %-28s %s\n' "$1" "$2"; }
echo "cloud_setup: $PROJECT_NAME at $PROJECT_DIR"

# 1. Identity, set GLOBALLY rather than per repository: the working-docs repo is often cloned
#    mid-session so a per-repo setting would miss it, and any repo cloned later inherits the global
#    one. Everything downstream resolves the owner from user.email, so this comes first.
resolve_owner
if [[ -n "${OWNER_DIR:-}" ]] || ! is_shared; then
  say "identity" "already ${OWNER_NAME:-${OWNER_EMAIL:-set}}, left alone"
else
  want="${1:-}"
  table="$CLAUDE_DIR/work/owners.txt"
  line=""
  [[ -n "$want" && -f "$table" ]] && line="$(awk -v d="$want" '
      /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
      { gsub(/\t/, " ") }
      $2 == d { print; exit }
  ' "$table")"
  if [[ -z "$line" ]]; then
    echo "  identity: git user.email is '$(git config user.email 2>/dev/null || echo unset)'," >&2
    echo "  which work/owners.txt does not know. Re-run naming your owner directory:" >&2
    echo "      .claude/bin/cloud_setup.sh <owner-directory>" >&2
    echo "  Known: $(awk '!/^[[:space:]]*#/ && NF {gsub(/\t/," "); print $2}' "$table" 2>/dev/null | sort -u | tr '\n' ' ')" >&2
    exit 4
  fi
  email="$(awk '{print $1}' <<<"$line")"
  name="$(awk '{$1=""; $2=""; sub(/^  */,""); print}' <<<"$line")"
  git config --global user.email "$email"
  git config --global user.name "${name:-$want}"
  # A per-repo value shadows the global one and is exactly what an earlier session may have left
  # behind, so clear it in both repositories rather than setting three copies that can disagree.
  for r in "$PROJECT_DIR" "$CLAUDE_DIR"; do
    git -C "$r" config --unset user.name  2>/dev/null || true
    git -C "$r" config --unset user.email 2>/dev/null || true
  done
  say "identity" "set globally to ${name:-$want} <$email>"
fi

# 2. Commit signing off, globally. A container has no access to your signing key, and a repo
#    inheriting `commit.gpgsign=true` fails every commit with an error naming gpg rather than the
#    missing key.
if [ "$(git config --global commit.gpgsign 2>/dev/null || echo false)" = "true" ]; then
  git config --global commit.gpgsign false
  say "commit signing" "disabled (no key in a container)"
else
  say "commit signing" "already off"
fi

# 3. The working-docs repo. This script lives inside .claude/, so it cannot clone it for you, but
#    it can say so precisely, which is otherwise a whole session of conventions nobody loaded.
if [ -d "$CLAUDE_DIR/.git" ]; then
  say "working docs" "clone present ($(git -C "$CLAUDE_DIR" rev-parse --short HEAD 2>/dev/null || echo 'no commits'))"
elif [ -n "${DOCS_REPO_URL:-}" ]; then
  say "working docs" "NOT a clone; run: $(clone_hint)"
else
  say "working docs" "NOT a clone; .claude/ should be one, see .claude/README.md"
fi

# 4. A checkout that lost the executable bit turns every hook into a silent no-op, which looks
#    exactly like a hook that decided not to fire.
chmod +x "$CLAUDE_DIR"/hooks/*.sh "$CLAUDE_DIR"/bin/*.sh 2>/dev/null || true
say "hooks and bin" "executable"

# <!-- FILL IN: project-specific container setup, if any.
#
# Anything a fresh container needs that a laptop already has: a toolchain, a dependency restore, a
# submodule init, an env var pointing at a scratch directory. Keep each step idempotent and quiet
# when there is nothing to do, and never put a secret here: this file is committed.
#
# Example shape:
#   if ! command -v <tool> >/dev/null; then <install it>; say "<tool>" "installed"; else say "<tool>" "present"; fi
# -->

echo "cloud_setup: done. Run .claude/bin/cloud_ready.sh to confirm."
