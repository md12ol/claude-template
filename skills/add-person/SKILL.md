---
name: add-person
description: Switch a solo working-docs repo to a shared one — restore the coordination files /setup removed, write the owner table, install the union merge driver and move live tasks under an owner. Use when a second person is about to start working on a project that was set up solo.
---

# Add person

Turn a `PEOPLE="solo"` install into a `PEOPLE="shared"` one. **This is not `/setup`**, which
interviews you about a new project and runs once ever; this runs whenever the number of people
changes and asks about one thing only: who is joining.

**Do it before they clone, not after.** Someone who clones a repo still saying `PEOPLE="solo"` gets
live tasks at `work/current/` and no owner table; this skill then moves the directory under them,
and their next `/save` pushes a plan the other session has already moved.

## 1. Collect the addresses — from the people, not from the log

Ask each person for the git email they commit with and a short directory name. **One line per
address:** work, personal and host `noreply` addresses are three entries pointing at one directory.
A missing address stops that person's session dead, which is deliberate — but it should stop them on
day one, not day thirty. What someone commits with is often not what their host reports, so **never
guess an email**: a wrong entry routes their work into a directory nobody opens.

You need **everyone**, the existing owner included — the table was removed when there was only one
person, so it has nobody in it.

## 2. Run the script

```bash
.claude/bin/add_person.sh <email> <dir> "<name>" <email> <dir> "<name>"
```

It restores what the solo install removed (`collab.md`, `collab_settled.md`, `owners.txt`,
`gitattributes.multi-writer`, `skills-optional/`, `work/meetings/`), writes the owner table, moves
`work/current` and `work/parked` under your own directory, flips `PEOPLE` to `shared`, installs and
verifies the merge driver, and checks that the paths now resolve. It does not commit.

It refuses, changing nothing, when: the install is already `shared` (a third person is one more line
in `work/owners.txt` and nothing else); the docs tree is dirty; fewer than two people were given; or
your own git email is not among them. It also refuses when the commit that removed those files is
not in history — a squashed or re-created repository. In that case take the files from the template
this repo came from and **never write a remembered copy**: a seed that drifts from the real one is
how two versions of the same rules start disagreeing.

**`work/archive/` and `work/meetings/` never move under an owner.** A finished task is the project's
history and a meeting belongs to everyone; only *live* tasks are per-owner.

## 3. Restore the CLAUDE.md sections by hand

The script prints the SHA and the headings the solo removal deleted from `CLAUDE.md`. Put those
back: the persistent-docs rows for `collab.md` and `collab_settled.md`, the `work/owners.txt` row,
the `PEOPLE` paragraph, and the whole **"More than one person uses this `.claude/`"** section
including **"Formatting for union merge"**.

**Never restore the whole file** from that commit. It has been edited since, and those edits are
this project's.

## 4. Commit, push, then tell them to clone

```bash
git -C .claude add -A
git -C .claude commit -m "Switch to a shared working-docs repo, adding <name>"
git -C .claude push
```

**Push before they clone.** That is the whole ordering this skill exists to get right, and it is a
deliberate exception to "don't commit or push unless asked" — the `.claude/` repository only.

Then report: who was added, where live tasks now live, that the merge driver verified, and the one
thing they need — the clone command from `project.conf`'s `DOCS_REPO_URL`.
