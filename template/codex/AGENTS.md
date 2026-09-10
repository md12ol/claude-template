# Project bootstrap for Codex

This project's working rules and workflows live in `.claude/`. **Do not duplicate them here.**

Before doing task work:

1. If `.claude/CLAUDE.md`, `.claude/skills/` or `.claude/work/` is missing, **stop** and tell the
   user. `.claude/project.conf` names the working-docs repository and its clone URL when this
   project uses the fork layout; on the copy layout the directory is simply part of the checkout
   and its absence means something was deleted.
2. **Read `.claude/CLAUDE.md` completely** and treat it as the project-specific working rules. More
   specific platform, system, developer or user instructions still take precedence.
3. If `.claude/settings.local.json` selects an `outputStyle`, read the matching file under
   `.claude/output-styles/` and follow it as repository response-style guidance.
4. Treat `.claude/skills/*/SKILL.md` as the **canonical** workflow definitions. Codex reaches them
   through compatibility wrappers in `.agents/skills`; **read the canonical file completely**
   whenever a wrapper selects one.
5. Read `.claude/codex/ADAPTER.md` when translating a Claude-specific instruction or tool name.

`.claude/` is the source of truth. **Never copy a workflow body into this file or into a wrapper**,
and never modify a canonical workflow merely to make Codex accept it.
