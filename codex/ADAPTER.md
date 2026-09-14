# Codex adapter

**How to read this project's Claude Code workflows when running under Codex.** It translates
host-specific mechanics only — tool names, invocation syntax, frontmatter that does not apply — and
never changes what a workflow means or which of its stops are required. The selected
`.claude/skills/<name>/SKILL.md` is **canonical**: read it completely, then follow its intent and
safety boundaries, translating only what is listed here.

- **Ignore Claude-only frontmatter** such as `model:` or `allowed-tools:`. The active Codex model
  stays in effect unless the user explicitly asks to change it.
- **A canonical `/name` invocation corresponds to `$name` in Codex.** A reference to another
  canonical workflow means *load that workflow*; it does not permit its side effects.
- **`AskUserQuestion` means Codex's structured user-input mechanism**, or the same concise question
  as plain text where there is none. **Preserve every required stop, confirmation and
  one-action-at-a-time boundary** — what is most easily lost in translation, and costliest to lose.
- **`$CLAUDE_PROJECT_DIR` means the project root.** Never rename a variable in a canonical hook.
- **Repository operations:** prefer a connected host integration; fall back to the configured CLI
  (`project.conf`, `TRACKER_CLI`) where the workflow needs what the integration does not expose.
  Preserve every confirmation rule in `CLAUDE.md` either way.
- **Do not invent substitutes for unavailable tools.** Use an equivalent safe mechanism where one
  genuinely exists; otherwise **stop and explain the exact incompatibility**.

Run `.claude/codex/check_bridge.sh` after adding, removing, renaming or changing the frontmatter of
a canonical skill; body changes reach Codex through these wrappers with nothing copied.
