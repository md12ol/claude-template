# Codex bridge

Makes this project's Claude Code workflows available to Codex **without changing or copying their
canonical instructions**. Claude Code loads nothing from this directory, so installing the bridge
cannot change how Claude behaves.

The design point is that nothing is forked: the wrappers are three-line files that point at the
canonical `SKILL.md`, so a change to a workflow reaches both hosts at once. A bridge that copied
skill bodies would be two systems drifting apart within a week.

## Install

From the project root, once per clone per machine:

```bash
.claude/codex/install.sh          # bash, macOS, Linux, WSL
.claude/codex/install.ps1         # native Windows PowerShell
```

Both are idempotent and:

- add `/AGENTS.md`, `/.agents/` and `/.codex/` to that clone's **private** `.git/info/exclude`, so
  the generated entrypoints are never committed;
- link those Codex discovery locations at `.claude/codex/`;
- **refuse** to replace an existing file or an unexpected symlink; and
- validate the bridge and its wrappers.

The bash installer uses relative symlinks and needs symlink support. The PowerShell installer uses
hard links for files and a directory junction for the wrappers, because Windows symlinks need
either Developer Mode or an elevated prompt. Both expose the same canonical files.

If the same checkout moves between WSL and native Windows, re-run the installer for whichever
environment will launch Codex. Then restart Codex and review the project hooks with `/hooks` before
trusting them.

## After changing a skill

```bash
.claude/codex/check_bridge.sh
```

Run it whenever a canonical skill is added, removed, renamed, or has its frontmatter changed. A
wrapper for a skill that no longer exists fails silently: Codex offers the command and it does
nothing.
