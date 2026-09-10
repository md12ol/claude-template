#!/usr/bin/env bash
# Regenerate the Codex skill wrappers from the canonical skills.
#
#     .claude/codex/generate_wrappers.sh
#
# A wrapper is three lines pointing at the canonical SKILL.md, plus that skill's own name and
# description so Codex can offer it. Nothing is forked: change a workflow once and both hosts see it.
#
# Run this after adding, removing or renaming a canonical skill. check_bridge.sh verifies the
# result and is what tells you a wrapper has gone stale.
set -euo pipefail

BRIDGE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$BRIDGE")"
mkdir -p "$BRIDGE/skills"

# Drop wrappers whose canonical skill is gone. A wrapper with no target is the silent failure this
# whole script exists to prevent: Codex offers the command and it does nothing.
for w in "$BRIDGE"/skills/*/; do
    [[ -d "$w" ]] || continue
    n="$(basename "$w")"
    [[ -f "$CLAUDE_DIR/skills/$n/SKILL.md" ]] || { rm -rf "$w"; echo "  removed  $n (no canonical skill)"; }
done

for canonical in "$CLAUDE_DIR"/skills/*/SKILL.md; do
    [[ -f "$canonical" ]] || continue
    name="$(basename "$(dirname "$canonical")")"
    desc="$(sed -n '2,/^---$/s/^description: *//p' "$canonical" | head -1)"
    mkdir -p "$BRIDGE/skills/$name"
    cat > "$BRIDGE/skills/$name/SKILL.md" <<WRAP
---
name: $name
description: $desc
---

Read [the shared Codex adapter](../../ADAPTER.md), then read and execute the complete canonical
[$name workflow](../../../skills/$name/SKILL.md). The canonical file is the source of truth.
WRAP
    echo "  wrapped  $name"
done
