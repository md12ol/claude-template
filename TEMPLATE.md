# About this template

*This file is about the template itself, not about your project. Once you have run `/setup` you can
delete it — nothing depends on it.*

This repository is a starting point for tracking work with
[Claude Code](https://claude.com/claude-code). Its root **is** a `.claude/` directory: create your
own copy of it, clone that into a project, and you have the whole system.

## Starting a new project

```bash
# 1. On your host, make your own copy of this repository, named <project>-claude.
#    GitHub: "Use this template" (or Fork).  GitLab: Fork.  Anywhere: clone and change the remote.

# 2. Clone it into the project it belongs to, as .claude/
cd ~/code/myproject
git clone <your-copy-url> .claude

# 3. Open Claude Code there and run:
/setup
```

`/setup` reads the repo, asks what it cannot infer, writes `project.conf` and `CLAUDE.md`, wires the
hooks that apply, and adds `.claude/` to the project's `.gitignore`. Then `/start` your first task.

**Step 3 is the only step with a decision in it.** The rest is one repository copy and one clone.

## Why `.claude/` is a separate repository

- **It never enters your project's history**, so it never ships inside a built artifact, a package,
  or a release tarball.
- **It is never frozen on a branch.** Tracked inside the project, a feature branch's copy of your
  plan is stuck at the moment the branch was cut, and switching branches silently changes what the
  last session was doing.
- **Work is recorded even when the code is not.** `/save` commits and pushes the live task
  directory, so a task started on one machine resumes on another.

The cost, accepted deliberately: commits are not atomic across the two repositories, and "what did
the plan say when this commit landed" is a timestamp lookup rather than one SHA.

## Your copy is yours

Once cloned, it diverges — rewrite a skill, delete one, change the rules, rename files. **Nothing
here expects changes to come back**, no hook checks the template for updates, and nothing goes stale
because the template moved on.

If you ever *want* something from a newer version, it is a merge you choose to run:

```bash
git remote add upstream <this template's URL>     # optional, once
git fetch upstream && git merge upstream/main     # only when you actually want it
```

## Keeping the template itself healthy

If you are changing the template rather than using it:

```bash
./test.sh        # 108 checks
./test.sh -v     # list every one
```

Both team shapes, the park round trip, the command tiers, the merge-driver narrowing, the Codex
bridge and the cloud pair. CI runs it on push for GitHub and GitLab both, because the template must
not assume a host.

**Every case corresponds to a defect that was actually found, or to a claim the README makes.** When
you fix a bug, add the case that would have caught it — and check that the case fails before the
fix, since a check that cannot fail is worse than no check.

## Licence

MIT.
