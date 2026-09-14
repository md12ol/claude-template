#!/usr/bin/env bash
# Validate the Codex bridge. Read-only; run it after any change to a canonical skill.
#
#     .claude/codex/check_bridge.sh
set -uo pipefail

BRIDGE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$BRIDGE")"
PROJECT_DIR="$(dirname "$CLAUDE_DIR")"
failed=0
fail() { echo "FAIL: $*" >&2; failed=1; }

frontmatter() {  # frontmatter <key> <file>
    sed -n "2,/^---$/s/^${1}: *//p" "$2" | head -1 | tr -d '\r'
}

[[ -f "$BRIDGE/AGENTS.md" ]]  || fail "codex/AGENTS.md is missing"
[[ -f "$BRIDGE/ADAPTER.md" ]] || fail "codex/ADAPTER.md is missing"

# JSON validity, if an interpreter is available. `python3` alone is not safe to assume: on Windows
# outside WSL, `python3` and `python` are Microsoft Store app-execution aliases that sit on PATH,
# print an advert and exit non-zero, so a bare `python3 … || fail` would report the file it was
# checking as broken rather than the interpreter as missing (`py` is the real launcher there). No
# interpreter is not a failure of the bridge, so it is a skipped check rather than a FAIL.
PY=""
for c in python3 python py; do
    command -v "$c" >/dev/null 2>&1 \
        && "$c" -c 'import sys; sys.exit(0 if sys.version_info[0]==3 else 1)' >/dev/null 2>&1 \
        && { PY="$c"; break; }
done
if [[ -n "$PY" ]]; then
    "$PY" -m json.tool "$BRIDGE/hooks.json" >/dev/null 2>&1 || fail "codex/hooks.json is not valid JSON"
else
    echo "SKIP: no Python 3 found (tried python3, python, py) — hooks.json not JSON-checked"
fi

# Both directions matter: a missing wrapper means Codex cannot reach the workflow, an orphaned one
# means Codex offers a command that silently does nothing.
for canonical in "$CLAUDE_DIR"/skills/*/SKILL.md; do
    [[ -f "$canonical" ]] || continue
    name="$(basename "$(dirname "$canonical")")"
    wrapper="$BRIDGE/skills/$name/SKILL.md"
    [[ -f "$wrapper" ]] || { fail "no Codex wrapper for skill '$name' — run generate_wrappers.sh"; continue; }

    [[ "$(frontmatter name "$wrapper")" == "$name" ]] \
        || fail "wrapper '$name' has a mismatched name in its frontmatter"
    [[ "$(frontmatter description "$wrapper")" == "$(frontmatter description "$canonical")" ]] \
        || fail "wrapper '$name' has a stale description — run generate_wrappers.sh"
    grep -q "skills/$name/SKILL.md" "$wrapper" \
        || fail "wrapper '$name' does not point at its canonical file"
    grep -q 'ADAPTER.md' "$wrapper" \
        || fail "wrapper '$name' does not reference the adapter"
done

for wrapper in "$BRIDGE"/skills/*/; do
    [[ -d "$wrapper" ]] || continue
    name="$(basename "$wrapper")"
    [[ -f "$CLAUDE_DIR/skills/$name/SKILL.md" ]] \
        || fail "orphaned Codex wrapper '$name' — no canonical skill. Run generate_wrappers.sh"
done

# The entrypoints, if the bridge has been installed in this clone.
for pair in "AGENTS.md" ".agents/skills" ".codex/hooks.json"; do
    p="$PROJECT_DIR/$pair"
    [[ -e "$p" || -L "$p" ]] || continue
    [[ -e "$p" ]] || fail "broken link: $pair -> $(readlink "$p" 2>/dev/null)"
done

if [[ $failed -eq 0 ]]; then
    echo "check_bridge: ok ($(find "$BRIDGE/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ') wrappers)"
fi
exit $failed
