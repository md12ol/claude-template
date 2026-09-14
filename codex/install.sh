#!/usr/bin/env bash
# Install the Codex bridge in this clone. Idempotent; refuses to overwrite anything.
#
#     .claude/codex/install.sh
#
# Run once per clone per machine. The three entrypoints go into .git/info/exclude, private to this
# clone, rather than .gitignore, which everyone would carry whether or not they use Codex.
set -euo pipefail

BRIDGE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$BRIDGE")"
PROJECT_DIR="$(dirname "$CLAUDE_DIR")"

git_dir="$(git -C "$PROJECT_DIR" rev-parse --absolute-git-dir 2>/dev/null)" || {
    echo "Refusing to install outside a git working tree: $PROJECT_DIR" >&2; exit 1
}

exclude="$git_dir/info/exclude"
mkdir -p "$(dirname "$exclude")"; touch "$exclude"
for entry in /AGENTS.md /.agents/ /.codex/; do
    grep -Fqx "$entry" "$exclude" || printf '%s\n' "$entry" >> "$exclude"
done

link() {  # link <path> <relative-target>
    local path="$1" target="$2"
    mkdir -p "$(dirname "$path")"
    if [[ -L "$path" ]]; then
        [[ "$(readlink "$path")" == "$target" ]] && return 0
        echo "Refusing to replace an unexpected symlink: $path -> $(readlink "$path")" >&2; exit 1
    fi
    [[ -e "$path" ]] && { echo "Refusing to replace an existing path: $path" >&2; exit 1; }
    ln -s "$target" "$path"
    echo "  linked   ${path#$PROJECT_DIR/}"
}

"$BRIDGE/generate_wrappers.sh"

link "$PROJECT_DIR/AGENTS.md"        ".claude/codex/AGENTS.md"
link "$PROJECT_DIR/.agents/skills"   "../.claude/codex/skills"
link "$PROJECT_DIR/.codex/hooks.json" "../.claude/codex/hooks.json"

"$BRIDGE/check_bridge.sh"
echo "Codex bridge installed. Restart Codex, then review and trust the project hooks with /hooks."
