# About this template

*This file is about the template itself, not about your project. Once you have run `/setup` you can
delete it — nothing depends on it.*

This repository is a starting point for tracking work with
[Claude Code](https://claude.com/claude-code). Its root **is** a `.claude/` directory: make your own
copy of it, clone that into a project, and you have the whole system.

## Starting a new project

```bash
# 1. Make your own copy of this repository, named <project>-claude.
#    On GitHub: the "Use this template" button, or
gh repo create <you>/myproject-claude --template <you>/claude-template --private

# 2. Clone it into the project it belongs to, as .claude/
cd ~/code/myproject
git clone <your-copy-url> .claude

# 3. Open Claude Code there and run:
/setup
```

**Use a template copy, not a fork**, and make it **private**. The first two reasons stop you
outright: you cannot fork your own repository into your own account on GitHub, which is what
`<you>/claude-template` → `<you>/myproject-claude` would be; and a fork of a public repository is
always public, while this one will hold your plans, decisions and session notes. A fork's upstream
link buys nothing here either — nothing is expected to flow back. **Prerequisite, once:** the source
repository must be marked a *template repository* in its settings, or the button does not appear and
`--template` is rejected; in a fresh copy that is already done. **On another host, or none:** clone
this repository, delete its `.git`, and push the result somewhere new.

`optional/` holds pieces only some projects want, inert until `/setup` copies them into place.

`/setup` reads the repo, asks what it cannot infer, writes `project.conf` and `CLAUDE.md`, wires the
hooks that apply, adds `.claude/` to the project's `.gitignore`, and removes whatever cannot apply —
a solo project does not keep the coordination files, and a project that will never run Codex does
not keep the bridge. Then `/start` your first task. **Step 3 is the only step with a decision in
it**; the rest is one copy and one clone.

## Why `.claude/` is a separate repository

- **It never enters your project's history**, so it never ships inside a built artifact or a
  release tarball.
- **It is never frozen on a branch.** Tracked inside the project, a feature branch's copy of your
  plan is stuck at the moment the branch was cut, and switching branches silently changes what the
  last session was doing.
- **Work is recorded even when the code is not.** `/save`, `/park` and `/done` commit and push the
  task directories, so a task started on one machine resumes on another.

The deliberate cost: commits are not atomic across the two repositories, so "what did the plan say
when this commit landed" is a timestamp lookup rather than one SHA.

## Your copy is yours, and diverges

Once cloned it diverges — rewrite a skill, delete one, change the rules, rename files. **Nothing
here expects changes to come back**, nothing checks for updates, and nothing goes stale because the
template moved on. If you ever *want* something from a newer version, it is a merge you choose:

```bash
git remote add upstream <this template's URL>     # optional, once
git fetch upstream && git merge upstream/main     # only when you actually want it
```

## Keeping the template itself healthy

```bash
./test.sh -v          # the synthetic fixtures: both team shapes, the hooks, the bridge
./test_fixture.sh -v  # the same machinery over a real working-docs tree; self-skips without one
```

CI runs both on push, for GitHub and GitLab alike, because the template must not assume a host.
**Every case corresponds to a defect actually found, or to a claim the README makes.** When you fix
a bug, add the case that would have caught it — and check it fails before the fix, since a check
that cannot fail is worse than none.

MIT licence.
