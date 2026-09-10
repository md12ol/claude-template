# Codex adapter

**How to read this project's Claude Code workflows when running under Codex.** It translates
host-specific mechanics only — tool names, invocation syntax, frontmatter that does not apply — and
never changes what a workflow means or which of its stops and confirmations are required.

The selected `.claude/skills/<name>/SKILL.md` is **canonical**. Read it completely, then follow its
intent and safety boundaries while translating only the host-specific mechanics below.

- **Ignore Claude-only frontmatter** such as `model:` or `allowed-tools:`. The active Codex model
  stays in effect unless the user explicitly asks to change it.
- **A canonical `/name` invocation corresponds to `$name` in Codex.** A reference to another
  canonical workflow means *load that workflow*; it does not grant permission for its side effects.
- **`AskUserQuestion` means use Codex's structured user-input mechanism.** If none is available,
  ask the same concise question as plain text. **Preserve every required stop, confirmation and
  one-action-at-a-time boundary** — those are the parts most likely to be lost in translation, and
  the parts whose absence costs the most.
- **`$CLAUDE_PROJECT_DIR` means the project root** when interpreting a command. Do not modify the
  canonical hook scripts to rename a variable.
- **Repository operations:** prefer a connected host integration for metadata and supported
  actions; fall back to the project's configured CLI (`project.conf`, `TRACKER_CLI`) when the
  workflow needs behaviour the integration does not expose. Preserve every confirmation rule in
  `CLAUDE.md` either way.
- **Do not invent substitutes for unavailable tools.** Continue with an equivalent safe mechanism
  when one genuinely exists; otherwise **stop and explain the exact incompatibility**.

Changes to canonical workflow bodies take effect through these wrappers without copying anything.
Run `.claude/codex/check_bridge.sh` after adding, removing, renaming, or changing the frontmatter of
a canonical skill.
