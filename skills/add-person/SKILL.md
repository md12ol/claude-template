---
name: add-person
description: Switch a solo working-docs repo to a shared one — restore the coordination files /setup removed, add the new person to work/owners.txt, install the union merge driver, and move live tasks into per-owner directories. Use when a second person is about to start working on a project that was set up solo.
---

# Add person

Turn a `PEOPLE="solo"` install into a `PEOPLE="shared"` one. Everything `/setup` removed as
inapplicable is restored from the commit that removed it, and the live task directory moves under an
owner.

**This is not `/setup`.** `/setup` interviews you about a new project and runs once, ever. This runs
whenever the number of people changes, and it asks about one thing only: who is joining.

**Do it before they clone, not after.** A person who clones a repo that still says `PEOPLE="solo"`
gets a session with live tasks at `work/current/` and no owner table, then this skill moves the
directory under them, and their next `/save` pushes a plan the other person's session has already
moved. Ten minutes of ordering avoids a genuinely confusing hour.

## 1. Check where you are

```bash
grep '^PEOPLE=' .claude/project.conf
git -C .claude status --short
```

- **Already `shared`** — this has run, or the repo was never solo. Say so and stop. If someone new
  is joining an already-shared repo, the whole job is §3: add their line to `work/owners.txt`.
- **A dirty `.claude/` tree** — stop and report. This skill moves and restores files, and a
  half-finished edit underneath that is very hard to read afterwards.
- **A live task in `work/current/`** — fine, and §4 moves it. Note it now so you can confirm it
  arrived.

## 2. Restore what solo removed

The removal was one commit, found by content rather than by remembering a SHA:

```bash
sha="$(git -C .claude log --diff-filter=D --format=%H -1 -- work/collab.md)"
git -C .claude checkout "$sha^" -- work/collab.md work/collab_settled.md \
                                   work/owners.txt gitattributes.multi-writer skills-optional
mkdir -p .claude/work/meetings
```

Confirm each arrived; a `checkout` of a path that was never in that commit fails loudly, but a
partial restore is worth seeing:

```bash
ls .claude/work/collab.md .claude/work/collab_settled.md .claude/work/owners.txt \
   .claude/gitattributes.multi-writer .claude/skills-optional
```

**If that commit is not in history** — a squashed or re-created repository — take the files from the
template this repo came from. **Do not write a remembered copy**: a seed that drifts from the real
one is how two versions of the same rules start disagreeing, and this file is the one that governs
how disagreements get resolved.

`CLAUDE.md`'s deleted sections are in the same commit. Restore them by hand from
`git -C .claude show "$sha^":CLAUDE.md` — the persistent-docs rows for `collab.md` and
`collab_settled.md`, the `work/owners.txt` row, the `PEOPLE` paragraph, and the whole
**"More than one person uses this `.claude/`"** section including **"Formatting for union merge"**.
Do not restore the whole file: it has been edited since, and those edits are this project's.

## 3. Add both people to `work/owners.txt`

Ask for the new person's git email and a short directory name, and add the existing owner too — the
file was removed when there was only one, so it has nobody in it.

```
<git-email>	<directory-name>	<display name>
```

**One line per address.** A work address, a personal one and a host `noreply` address are three
lines pointing at one directory. An address missing here stops that person's session dead, which is
deliberate — but it should stop them on day one, not on day thirty.

Get the new person's addresses **from them**, not from `git log`: the address they commit with is
often not the one their host reports, and guessing produces a table that looks right and fails.

## 4. Move live and parked tasks under their owner

```bash
cd .claude
mkdir -p "work/<owner>"
[[ -e work/current ]] && git mv work/current "work/<owner>/current"
[[ -e work/parked  ]] && git mv work/parked  "work/<owner>/parked"
mkdir -p work/current   # removed below once nothing looks for it
rmdir work/current 2>/dev/null
```

**`work/archive/` and `work/meetings/` do not move.** A finished task is the project's history and a
meeting belongs to everyone; only *live* tasks are per-owner. Moving the archive under one person is
the kind of mistake nobody notices until the other person cannot find last month's work.

## 5. Flip the switch and install the merge driver

```bash
sed -i 's/^PEOPLE=.*/PEOPLE="shared"/' .claude/project.conf
cp .claude/gitattributes.multi-writer .claude/.gitattributes
```

Then **verify the driver took**, because getting it wrong is silent — git reads `.gitattributes`
only from the repository containing the file:

```bash
git -C .claude check-attr merge -- work/decisions.md work/traps.md
# expect: decisions.md -> union, traps.md -> unspecified
```

`traps.md` staying `unspecified` is not an omission. It is a churn list, where deleting an entry is
normal, and union merge cannot express a deletion: a delete racing any edit to the same region is
silently discarded and the entry comes back.

## 6. Check it resolves for both people

```bash
. .claude/hooks/lib.sh && load_conf && resolve_owner && echo "$WORK_CURRENT"
.claude/hooks/session_brief.sh
```

`$WORK_CURRENT` must now be `work/<owner>/current`, and the brief must show your task, not "no
active task". If the brief says the identity is unrecognised, the address in `work/owners.txt` does
not match `git config user.email` — fix the table, not the identity.

## 7. Commit, push, then tell them to clone

```bash
git -C .claude add -A
git -C .claude commit -m "Switch to a shared working-docs repo, adding <name>"
git -C .claude push
```

**Push before they clone.** That is the whole ordering this skill exists to get right.

Then report: who was added, where live tasks now live, that the merge driver is verified, and the
one thing they need — the clone command from `project.conf`'s `DOCS_REPO_URL`.

## Constraints

- **Never guess an email.** Ask. A wrong entry routes someone's work into a directory nobody opens.
- **Never move `work/archive/` or `work/meetings/`** under an owner.
- **Never restore `CLAUDE.md` wholesale** from the old commit — only the deleted sections.
- **Do not run this to add a third person** to an already-shared repo. That is §3 alone.
