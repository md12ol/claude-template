---
name: setup
description: Initialize the .claude working-docs system in a project for the first time — inspect the repo, interview the user, and fill in the FILL IN blocks in .claude/CLAUDE.md. Run ONCE, right after cloning the working-docs repo as .claude/. Use when CLAUDE.md still contains FILL IN blocks, when the user says to set up / configure / initialize the docs system, or when they ask what to do after cloning the working docs into a new project.
---

# Setup

Turn the freshly-installed template into **this project's** rules. Run once, right after
cloning the working-docs repo as `.claude/`. Not to be confused with:

| | |
|---|---|
| `/setup` | configures the **project**. Once, ever. ← you are here |
| `/start` | opens a **task**. Once per piece of work |
| `/done` | closes a task |

At the end of `/setup`, `.claude/CLAUDE.md` should contain no `FILL IN` blocks and no rule that
doesn't apply here.

## 0. Check it hasn't already run

```bash
grep -c 'FILL IN' .claude/CLAUDE.md
```

- **No `.claude/CLAUDE.md`** → the working docs aren't cloned yet. Say so, point at
  a fresh clone, stop.
- **Zero `FILL IN` blocks** → setup already ran. **Don't redo it.** Say so, show the section
  headings that exist, and ask whether they want to revise one specific section. Never regenerate a
  `CLAUDE.md` that already carries project rules — those rules were earned.
- **Some remain** → continue. A partial run is normal; only fill what's still open.

## 1. Investigate before asking

**Do this first.** Most of what the FILL IN blocks want is visible in the repo, and a question you
could have answered yourself is a bad question. Gather:

**Shape of the project**
```bash
ls; git rev-parse --show-toplevel; git branch --show-current
```
Look for the build/dependency manifest — `package.json`, `pyproject.toml`, `setup.py`, `Cargo.toml`,
`go.mod`, `Makefile`, `CMakeLists.txt`, `pom.xml`, `Gemfile`, `docker-compose.yml`, `*.nix`. That
gives you the language, and usually the run/test commands.

**Multiple repos?**
```bash
cat .gitmodules 2>/dev/null; find . -name .git -maxdepth 3 -not -path './.git' 2>/dev/null
```
Also check for vendoring manifests (`gitman.yml`, `vendir.yml`, `repo` manifests). If
work spans more than one repo, block 2 is mandatory — an agent running `git status` at the root
would otherwise believe it has seen everything.

**Tracker**
```bash
git remote -v
```
`github.com` → `gh` · `gitlab.*` → `glab` · neither → ask. Note the host if it's self-hosted; that
detail costs an hour when it's missing.

**Is `.claude/` tracked?**
```bash
git check-ignore -v .claude 2>/dev/null || echo "tracked"
```

**Existing conventions** — read `CONTRIBUTING.md`, `.editorconfig`, linter configs, an existing
root `CLAUDE.md` or `AGENTS.md`. If the project already documents a rule, adopt its wording rather
than inventing a competing one.

Then say what you found, in a few lines, before asking anything. It gives the user something to
correct instead of something to compose.

## 2. Ask — always through `AskUserQuestion`, never as prose

**Every question in this step MUST go through the `AskUserQuestion` tool.** Do not ask in prose, do
not present a numbered list and wait, do not bury a question in a paragraph. The user configures a
project once and should be able to do it by clicking, not by composing answers to an essay.

Batch up to 4 per call, one question per topic, and **repeat the call** until everything is answered.
Lead every question with your best inference marked `(Recommended)` so the common case is one click,
and give each option a `description` saying what it actually costs or implies.

**The one question you must always ask — block 1, who runs the environment.** Never infer it. The
repo shows you *what* the commands are; only the user knows which ones an agent must not run. Ask
concretely, using the commands you actually found:

> **Question:** I found `docker compose up`, `make test` and `./deploy.sh` in this repo. Which
> should I run myself, and which do you always run?
>
> - *Agent runs tests and builds, never deploy or anything shared* **(Recommended)**
> - *Agent runs everything*
> - *Agent runs nothing — hands off every command*

Get the **command names**, not a category — the rule is only enforceable if it names binaries. If
they pick a middle option, follow up with a second question listing the specific commands you found
so the boundary is exact.

**The other questions**, asked only when the repo makes them relevant — batch them with the first:

| Ask | Only if | Options |
|---|---|---|
| Does the agent file issues for you, and where? | a git remote exists | the detected project · a different one · never files issues |
| Which paths are off-limits or owned by someone else? | vendored dirs or multiple repos found | the detected paths · none · free-text |
| Track `.claude/` in git? | `.claude/` is currently ignored | track the machinery, ignore only `work/current` **(Recommended)** · keep it all ignored |
| Enable the optional hooks? | always | see step 4 — one question per hook that applies |

### The two shape questions — always ask both, never infer either

These write `PEOPLE` and `MACHINES` into `project.conf`, and between them they decide what the rest
of this skill wires up. **They are separate questions because they gate different things**, and the
second is true far more often than people expect.

> **Question 1:** Will anyone other than you write to these working docs?
>
> - *Just me* **(Recommended when the remote has one contributor)**
> - *Yes — a team shares this directory*

`shared` turns on: the union merge driver, `collab_settled.md`, per-owner live task directories
(`work/<owner>/current/`), and the owner table in `work/owners.txt`. `solo` keeps live tasks at
`work/current/` with no owner segment and no table to maintain.

> **Question 2:** Will you use this project from more than one machine — a second computer, or a
> cloud container?
>
> - *Yes* **(Recommended — most people are, and a wrong "no" here fails silently)**
> - *Just this one machine*

`multi` turns on: `pull_main.sh` at session start, the `Machine:` stamp `/save` writes into
`handoff.md`, and `/load`'s divergence check. **Do not fold this into question 1.** A solo developer
with a laptop and a desktop has the full staleness problem and no teammate; a co-located pair on one
shared machine has the opposite. Inferring one from the other is wrong in both directions.

**If they say `shared`, follow up for the owner table**: each person's git email and a short
directory name for them. Write those into `work/owners.txt`, one line per address — a person with a
work address, a personal one and a host `noreply` one gets three lines pointing at one directory.
An address missing from that file stops that person's session dead, which is the intended behaviour
and worth saying out loud when you ask.

**Ask about the tracker** only if a remote exists: does the agent file issues on their behalf, and
to which project? If they say no, delete block 3 outright.

**Ask about off-limits paths** only if you found vendored/shared directories or a multi-repo layout.

Don't ask about anything you can settle by reading the repo. Don't ask four questions when the
project is a single repo with no tracker and the answer to three of them is "delete that block".

## 2.5. Write `.claude/project.conf` — before CLAUDE.md, because everything reads it

Fill in every value from what you detected and what was answered. Nothing else in `.claude/` should
ever hardcode any of it.

```bash
PROJECT_NAME="<the project directory's name>"
DOCS_REPO_NAME="<name>-claude"          # this repo — the one cloned as .claude/
DOCS_REPO_URL="<clone URL>"             # paste the one the host actually gives you
DOCS_BRANCH="main"
HOST="github|gitlab|other"              # from `git remote -v`
TRACKER_CLI="gh|glab|none"              # NEVER inferred from HOST — ask
TRACKER_REPO="<owner/repo>"
PEOPLE="solo|shared"                    # question 1
MACHINES="single|multi"                 # question 2
```

Read `DOCS_REPO_URL` off the clone rather than asking for it:

```bash
git -C .claude remote get-url origin
```

**If `.claude/` is not a clone, stop.** It is meant to be one — this project's working-docs repo,
cloned into place. A copied directory has no history, no remote, and nothing for `/save` to push
to, so the work record this whole system exists to keep would live on one machine and nowhere else.
Say so and point at `.claude/README.md` rather than configuring around it.

## 3. Write `.claude/CLAUDE.md`

Edit in place, block by block. **Delete each `FILL IN` comment as you resolve it** — including its
`<!-- -->` wrapper and the worked example inside. A leftover example is worse than nothing; a future
session cannot tell the template's `docker compose up` from a real rule.

- **Block 1 — environment.** Write it in the imperative, name the actual commands, and say what to
  do *instead* ("hand off the exact command and the log markers for success/failure"). If the answer
  was "run everything", delete the block; don't write a rule that permits everything.
- **Block 2 — repo layout.** Fill the table only if work genuinely spans repos. **Date the branch
  column** (`Branch (as of <YYYY-MM-DD>)`). Add the 3–5 key paths you found. Single repo → delete.
- **Block 3 — filing issues.** Tool + host, who owns the credential, the per-issue confirmation
  rule, target project, and the label warning if the tracker creates unknown labels as a side
  effect. No tracker → delete.
- **Block 4 — files outside your scope.** Paths, and the pointer to `hotfixes.md` for per-file
  disposition. Nothing off-limits → delete.
- **House style** — fill the small `FILL IN` under Conventions with anything the linter configs or
  `CONTRIBUTING.md` told you. Nothing found → delete.

Leave everything not marked `FILL IN` alone. The working-docs model, the workflow, the three task
states and the conventions are the system itself, not project settings.

Replace `<PROJECT>` in the title with the real name.

## 3b. Check the backup wiring

`.claude/hooks/backup_docs.sh` ships with the template and is wired to `Stop` + `SessionEnd` in
`settings.json`. It derives its destination automatically —
`~/.claude-backups/<name-of-the-directory-containing-.claude>/<date>/` — so there is normally
nothing to configure. **Verify it rather than assume it:**

```bash
.claude/hooks/backup_docs.sh --force
```

It should print the destination. Confirm the project name in that path is the one you expect — it
comes from the directory name, so a checkout called `src` or `repo` produces a useless bucket. If it
is wrong, set `CLAUDE_DOCS_BACKUP_DIR` in `settings.local.json` under `env`, and say so in the
report.

If the user chose to **track `.claude/` in git**, tell them the backup is now belt-and-braces and
they may delete the two hooks from `settings.json`. Don't delete them unasked.

## 4. Offer the optional hooks

Read `.claude/hooks/README.md` and offer only the ones that now apply. **Ask about each
through `AskUserQuestion`** — one question per hook, not a prose list:

- **Block dangerous commands** — offer this whenever the answer to block 1 was anything other than
  "run everything", and **build the regex from the commands they named**. This is the difference
  between a rule that is written down and a rule that holds; prose rules do get violated.
- **Show hotfixes before editing owned files** — offer only if block 4 was filled in, with their
  paths in the pattern.
- **Session-start brief** — offer always. It's cheap and makes stale `[~]` items visible.
- **`pull_main.sh`** — offer **only when `MACHINES="multi"`**, and wire it to run *before* the brief
  so the brief reflects what the other machine pushed. On a single-machine install it is a network
  call at every session start that can never find anything, so do not offer it at all.
- **The cloud pair** — mention `hooks/cloud_setup.sh` and `checks/cloud_ready.sh` when
  `MACHINES="multi"`. Neither is a hook and neither is wired into `settings.json`: they are run by
  hand on a fresh container. Say what they do and move on.

Merge accepted hooks into `.claude/settings.json`, preserving the two backup hooks, then verify:

```bash
python3 -m json.tool .claude/settings.json > /dev/null && echo OK
```

A malformed `settings.json` disables every hook in it silently, so don't skip that check.

## 4a. Offer the response style

`.claude/output-styles/concise.md` ships with every install and nothing else mentions it, so ask
once rather than leaving it to be found by accident:

> **Question:** Use the concise response style? It caps explanation at about six lines, skips
> narration of what is about to happen, and asks you to flag risks in one line each.
>
> - *No, keep the default* **(Recommended — try it later once you know what you want)**
> - *Yes, enable it*

If yes, set `outputStyle` in `settings.local.json` — **not** `settings.json`. It is a personal
preference on one machine, and `settings.json` is shared with everyone else on the project.

## 4b. Ask whether this project uses Codex

`codex/` bridges the same workflows to Codex without forking any skill body. It is inert unless
`codex/install.sh` is run, but an inert directory nobody recognises is still something a reader has
to rule out.

> **Question:** Will anyone run Codex on this project?
>
> - *No* **(Recommended unless you already know otherwise)**
> - *Yes, keep the bridge*

If no:

```bash
git -C .claude rm -qr codex
```

Restorable from that commit exactly like the solo removals, and `/add-person` is not needed for it —
`git checkout <sha>^ -- codex` is the whole job. Say so in the report rather than leaving it to be
rediscovered.

If yes, tell them the bridge is installed per clone per machine with `.claude/codex/install.sh`, and
that `check_bridge.sh` must run after any skill is added, removed or renamed.

## 4c. Offer the meeting loop — only when `PEOPLE="shared"`

`/make-agenda`, `/start-meeting` and `/end-meeting` turn `collab.md` into a dated agenda, a
read-only research desk during the sitting, and an executor afterwards. They ship in
`skills-optional/` and are not active until moved:

```bash
for s in make-agenda start-meeting end-meeting; do mv .claude/skills-optional/$s .claude/skills/; done
mkdir -p .claude/work/meetings
```

**Offer them only if the team actually sits down together on a schedule.** Ask; do not assume from
`PEOPLE="shared"`. Two people who review each other's pull requests and never meet get three
commands they will never run, and an unused command in the list makes the used ones harder to find.

If they decline, leave `skills-optional/` where it is and say it can be moved later. Also leave
`work/pipeline_backlog.md` in place either way — it is a useful list on its own, and the meeting
skills are what *process* it, not what justify it.

## 5. Settle version control

`.claude/` is a clone of this project's working-docs repo. Two things follow, and neither is a
question with more than one sensible answer.

### The project must ignore `.claude/` — add the line, then say so

If both repositories track it, every commit touches two of them and the clone stops being
independent. This is required for the setup to work at all, so **write it rather than asking**:

```bash
git check-ignore -q .claude || printf '\n# Working docs — their own repository, cloned into place.\n.claude/\n' >> .gitignore
```

Then tell the user you added it, in one line, and show the line. This is a deliberate exception to
"ask before editing a tracked file": a question whose only correct answer is yes is a worse
experience than a clear statement of what changed, and a project that tracks `.claude/` twice is
broken in a way that surfaces later and confusingly.

**If `.gitignore` does not exist, create it** with just that entry.

### Write the project's own root `CLAUDE.md`

`.claude/root_CLAUDE.md.example` is the **only file that still loads when `.claude/` is missing
entirely** — a machine that never cloned it. No hook can report that case, because `settings.json`
and the hooks are inside the directory that is not there. Shipping the example without placing it
means the guard does not exist.

```bash
sed -e "s|<PROJECT>|$PROJECT_NAME|" -e "s|<DOCS_REPO_URL>|$DOCS_REPO_URL|" \
    .claude/root_CLAUDE.md.example > CLAUDE.md
```

Strip the leading `<!-- ... -->` explanation block as you write it — it is instructions to you, not
content for the file.

**If the project already has a root `CLAUDE.md`, do not overwrite it.** Show the user the short
pointer block and ask where to add it, or append it under a new heading. Their existing rules are
theirs; this adds a signpost, it does not replace anything.

Keep it short. It is a signpost, not a second copy of the rules — anything duplicated there drifts
from `.claude/CLAUDE.md` and then contradicts it, which is worse than the gap it was filling.

### The docs repo needs a reachable remote

`/save` pushes the live task directory, and that push is the whole reason the directory is tracked.
A clone with no remote fails silently at exactly the moment the work matters.

```bash
git -C .claude remote -v          # expect an origin
git -C .claude status --short     # expect a clean tree, or say what is uncommitted
```

### If `PEOPLE="solo"` — remove what cannot apply

**Do this; do not offer it.** Everything below describes coordination between people, and on a solo
install there is no second person for it to describe. Left in place it is worse than clutter: a
reader cannot tell a file that is empty because nothing happened from one that is empty because it
does not apply, and rules for a hazard that cannot occur teach everyone to skim rules.

```bash
git -C .claude rm -qr work/collab.md work/collab_settled.md \
                      work/owners.txt gitattributes.multi-writer \
                      skills-optional work/meetings
```

| Removed | Why it cannot apply |
|---|---|
| `work/collab.md`, `work/collab_settled.md` | a running agenda between people, and its archive |
| `work/owners.txt` | the email-to-directory table, read only when `PEOPLE="shared"` |
| `gitattributes.multi-writer` | the union merge driver — there is no second writer to merge with |
| `skills-optional/`, `work/meetings/` | the meeting loop and its output |

Then edit `CLAUDE.md` to match, or it keeps describing files that are gone:

- delete the **`collab.md`** and **`collab_settled.md`** rows from the persistent-docs table
- delete the whole **"More than one person uses this `.claude/`"** section, including its
  **"Formatting for union merge"** subsection
- in "How this `.claude/` is configured", delete the **`work/owners.txt`** row and shorten the
  **`PEOPLE`** paragraph to say live tasks are at `work/current/`

**Keep `work/pipeline_backlog.md`.** "Small changes to this working-docs system that block nobody"
is a useful list alone too — you apply them yourself instead of batching them to a sitting.

**If someone joins later, `/add-person` restores all of this** from the commit that removed it. The
removal is committed for exactly that reason, so nothing here is lost and nobody goes looking.

### If `PEOPLE="shared"` — the merge driver

Install the shipped file into the docs repo:

```bash
cp .claude/gitattributes.multi-writer .claude/.gitattributes
```

Then **verify it, because getting this wrong is silent** — git reads `.gitattributes` only from the
repository containing the file:

```bash
git -C .claude check-attr merge -- work/decisions.md work/traps.md
# expect: decisions.md -> union, traps.md -> unspecified
```

State the trade when you offer it, because it is real: **union merge never conflicts**, so a genuine
collision on the same entry merges silently and interleaved. That is why it covers only the three
append-only docs and not the churn lists, and why every entry needs a unique heading and a unique
timestamped stamp — the "Formatting for union merge" section of `CLAUDE.md` mandates both. Keep that
section and `work/collab.md`.

### If `PEOPLE="shared"` and the host supports it — reviewers

A pull request needs the right reviewer on it, and doing that from memory is the step people skip.

- **Where CODEOWNERS works**, a single line covering everything is symmetric and needs no
  maintenance: the host requests every listed owner *except* the author.
- **Where it does not, say so in `CLAUDE.md` rather than shipping a file that does nothing.**
  CODEOWNERS is a paid feature on private repositories on several hosts, including GitHub's free
  plan — the file sits there and is silently ignored. On those, reviewers are named at pull-request
  creation time instead.

Check which case applies before recommending either. A CODEOWNERS that does nothing is worse than
no CODEOWNERS, because everyone believes it is working.

### Tidy the template's own files

`TEMPLATE.md` documents the template, not this project. Offer to delete it — and `test.sh`,
`.github/workflows/test.yml` and `.gitlab-ci.yml` too if the user does not intend to keep testing
their own changes to the skills. Deleting is optional and nothing depends on it; say what each one
is for and let them choose.

## 5b. Commit what `/setup` changed, and say what you committed

**`/setup` commits its own work.** It has just written `project.conf`, rewritten `CLAUDE.md`, and on
a solo install deleted several files — and that deletion is the thing `--add-person` restores from,
so leaving it uncommitted would break the undo path at exactly the moment someone needs it.

```bash
git -C .claude add -A
git -C .claude commit -m "Configure this .claude/ for <project>"
```

This is a deliberate, narrow exception to "don't commit or push unless asked", alongside `/save`'s.
It does not widen: **it commits the `.claude/` repository only**, never the project, and it does not
push — the user may want to look first.

Then **list what went into it**, in a few lines: the two switches, the files removed if any, and the
hooks now wired. A commit nobody can see the shape of is a commit nobody trusts.

## 6. Report, then hand off to `/start`

Short. What each block says now, which blocks you deleted and why, which hooks are live, and the
version-control disposition. **Always state the two switches explicitly** — `PEOPLE` and `MACHINES`,
each with the one consequence the user will notice — because they are the settings that silently
change what every later session does, and the moment to correct a wrong answer is now:

> `PEOPLE=shared` — live tasks go in `work/<you>/current/`, and the append-only docs union-merge.
> `MACHINES=multi` — `/save` stamps the machine and pushes; `/load` stops if the two diverge.

Then:

> Setup is done — `CLAUDE.md` is now this project's rules. Start your first piece of work with
> `/start`.

Don't create `work/current/plan.md`. `/setup` configures the project; `/start` opens the task, and it
needs an objective agreed with the user that `/setup` has no way to know.

## Constraints

- **Run once.** Step 0 is a real gate, not a formality.
- **Never invent a rule the user didn't agree to.** An unasked-for constraint in `CLAUDE.md` is
  obeyed silently by every future session. When unsure, delete the block rather than guessing at it
  — an absent rule is visible, a wrong one isn't.
- Don't write `decisions.md`, `issues.md`, `hotfixes.md` or `traps.md` entries. They are empty
  because nothing has happened yet.
- Don't commit or push.
