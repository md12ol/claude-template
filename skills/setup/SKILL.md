---
name: setup
description: Configure this working-docs template for a project, once — inspect the repo, interview the user, resolve every FILL IN block and write project.conf. Use right after cloning the working docs as .claude/, when the user asks to set up or initialize the docs system, or when CLAUDE.md still has FILL IN blocks.
---

# Setup

Turn the freshly-installed template into **this project's** rules. `/setup` configures the project,
once ever; `/start` opens a task. When it finishes, nothing under `.claude/` carries a `FILL IN`
block or a rule that does not apply here.

## 0. Check it hasn't already run

```bash
grep -rl 'FILL IN —' .claude --exclude-dir=.git
```

Expect five files on a fresh clone: `CLAUDE.md` (five blocks plus a house-style block),
`comment_style.md`, `bin/cloud_setup.sh`, `bin/cloud_ready.sh` and `bin/comment_audit.sh`. **Match
the em dash, not the bare words**: live prose discusses "FILL IN blocks", so `grep 'FILL IN'`
reads a configured project as unfinished.

- **No `.claude/CLAUDE.md`** → the working docs are not cloned yet. Say so, point at a clone, stop.
- **Nothing printed** → setup already ran. **Don't redo it.** Show the headings that exist and ask
  whether to revise one section. Never regenerate a `CLAUDE.md` that carries project rules.
- **Some remain** → continue. A partial run is normal; fill only what is still open.

## 1. Investigate before asking

Most of what the blocks want is visible in the repo, and a question you could have answered yourself
is a bad one:

```bash
ls; git rev-parse --show-toplevel; git branch --show-current     # shape
cat .gitmodules 2>/dev/null; find . -name .git -maxdepth 3 -not -path './.git'   # more than one repo?
git remote -v; git check-ignore -v .claude 2>/dev/null || echo "tracked"   # host; is .claude/ ignored?
git -C .claude remote get-url origin                             # DOCS_REPO_URL — read it, don't ask
git branch -a --format='%(refname:short)' | head                 # an existing branch convention?
```

Look for the build or dependency manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`,
`Makefile`, `pom.xml`, `Gemfile`, `docker-compose.yml`, `*.nix`): it gives the language and usually
the run and test commands. Read vendoring manifests and existing conventions too (`CONTRIBUTING.md`,
linter configs, a root `CLAUDE.md`) and adopt the project's wording rather than a rival rule. **If
`.claude/` is not a clone with an `origin`, stop:** a copied directory has nothing for `/save` to
push to, so the work record would live on one machine and nowhere else.

Then say what you found in a few lines before asking anything: it gives the user something to
correct instead of something to compose.

## 2. Ask — always through `AskUserQuestion`, never as prose

**Every question here goes through the `AskUserQuestion` tool** — a project is configured once and
should be configurable by clicking. Batch up to 4 per call, **repeat** until all are answered, lead
each with your best inference marked `(Recommended)`, and say what each option costs.

**Always ask: who runs the environment.** Never infer it — the repo shows *what* the commands are,
only the user knows which an agent must not run. Ask concretely, with the commands you found:

> I found `docker compose up`, `make test` and `./deploy.sh`. Which should I run, and which do you
> always run yourself? *Tests and builds, never deploy or anything shared* **(Recommended)** ·
> *Everything* · *Nothing — hand off every command*

Get **command names**, not a category: the rule is enforceable only if it names binaries. On a
middle answer, follow up with the list you found so the boundary is exact.

**Always ask both shape questions**, never inferring one from the other — they gate different things
and a guess is wrong in both directions.

> **1.** Will anyone other than you write to these working docs? *Just me* · *A team shares it*
>
> **2.** Will you use this project from more than one machine, a second computer or a cloud
> container? *Yes* **(Recommended — a wrong "no" fails silently)** · *Just this one*

`shared` turns on the union merge driver, `collab.md`, the meeting skills and per-owner live task
directories, with `work/owners.txt` as the only copy of the table; `multi` turns on `pull_main.sh`,
the `Machine:` stamp and `/load`'s divergence check. A laptop and a desktop is `multi`; a co-located
pair on one machine is not. **On `shared`, follow up for the owner table**: each person's git email
and a short directory name, one line per address — work, personal and host `noreply` addresses are
three lines pointing at one directory, and a missing one stops that person's session dead, which is
intended and worth saying as you ask.

**The rest, only where the repo makes them relevant** — batch them with the above:

| Ask | Only if |
|---|---|
| Does the agent file issues, and to which project? | a git remote exists. No → block 3 is deleted |
| Which paths are off-limits or owned by someone else? | vendored dirs or multiple repos found |
| Which optional hooks? | see §5 — one question per hook that applies |

Settle what you can by reading the repo; don't ask four questions when three answers are "delete it".

### The switch questions, in the same batches

> **Tracker-first?** Asked only when `TRACKER_CLI` is not `none`. *Yes, the tracker owns anything
> with a lifecycle* **(Recommended)**: `work/issues.md`, `work/hotfixes.md` and `work/deferred.md`
> are removed, a finding is reported and then filed as an issue, and temporary code becomes a
> `TEMPORARY (<YYYY-MM-DD>)` comment at the site plus the issue whose closure removes it. · *No,
> keep the three files*: everything stays readable offline and in one repository, and nothing has to
> be filed to be recorded. With `TRACKER_CLI="none"` it is not a question and `TRACKER_FIRST="no"`,
> because there would be nowhere for the work to go.

> **Labels**, only when tracker-first. Two answers: the **kind labels**, exactly one of which every
> filed issue carries (`KIND_LABELS`, default `bug enhancement task investigation`; empty means pass
> no labels at all), and whether a workflow **derives** labels from the title or body, which makes
> `LABELS_DERIVED="yes"` and means an agent must never pass them. Most trackers create an unknown
> label silently on first use, so the set stays closed and "pass none" is a real answer. Ask too for
> the label that marks a decision nobody has ruled on yet (`NEEDS_RULING_LABEL`).

> **Branch naming**, always. `<owner>_<slug>` **(Recommended)** · `<slug>` · whatever convention
> `git branch -a` already shows, which beats a new one nobody uses. It becomes `BRANCH_PATTERN`, and
> `/start` makes the branch task one whenever the work routes through a pull request.

> **Review routing**, always, and it fills block 5: which paths go through a branch and a pull
> request and which take a direct push; who merges, since nobody merges their own pull request where
> there is more than one of you; and whether an agent may merge at all (*never unprompted; told to
> merge, it merges* is the usual answer). **Solo installs get the short form**: what needs a PR,
> often nothing, and that an agent never merges unprompted.

> **`model: sonnet` on the five task skills.** *Keep* **(Recommended)**: the lifecycle skills are
> mechanical, and the pin makes them cheap and predictable wherever they run. *Drop it* and each
> runs on whatever model the session is already using, which costs more and changes nothing about
> what they do. Dropping is five one-line deletions from the frontmatter of `start`, `save`, `load`,
> `park` and `done`, followed by `codex/generate_wrappers.sh`.

> **The attribution block in `settings.json`.** *Keep* **(Recommended)**: it suppresses agent
> co-authorship trailers, generated-with footers and session links in commits and pull requests,
> which most projects do not want in `git log` forever. *Remove it* and the harness's own defaults
> apply, which is right only where the team has said it wants them.

> **GitHub extras**, only when `HOST="github"` and `PEOPLE="shared"`: ask for each owner's GitHub
> login. They substitute into `optional/github/assign-owner.yml` (`const owners = ['<a>', '<b>'];`,
> replacing `__OWNER_LOGINS__`) and `optional/github/CODEOWNERS` (`*  @<a> @<b>`, replacing
> `__OWNER_HANDLES__`). Say what each is for before asking: the workflow requests the *other* owner
> on every pull request, and CODEOWNERS does the same natively but is a paid feature on private
> repositories, where it sits in the tree doing nothing and reporting nothing.

## 3. Write `.claude/project.conf` — before `CLAUDE.md`, because everything reads it

Every value comes from what you detected or were told; nothing else in `.claude/` may hardcode any:

```bash
PROJECT_NAME="<the project directory's name>"
DOCS_REPO_NAME="<name>-claude"          # this repo — the one cloned as .claude/
DOCS_REPO_URL="<clone URL>"             # read off the clone, not asked for
DOCS_BRANCH="main"
HOST="github|gitlab|other"              # from the remote
TRACKER_CLI="gh|glab|none"              # NEVER inferred from HOST — ask
TRACKER_REPO="<owner/repo>"
PEOPLE="solo|shared"                    # question 1
MACHINES="single|multi"                 # question 2
TRACKER_FIRST="no"                      # yes: the tracker owns work, and three files are removed
NEEDS_RULING_LABEL="needs-ruling"       # the label for a decision that must be ruled before work
BRANCH_PATTERN="<owner>_<slug>"         # how a task's feature branch is named
LABELS_DERIVED="no"                     # yes: a workflow derives labels, so an agent passes none
KIND_LABELS="bug enhancement task investigation"   # the closed set; empty means pass no labels
```

`.claude/bin/task.sh paths` prints all of them, which is how every hook and skill reads them.

## 4. Resolve every `FILL IN` block

Edit in place. **Delete each block as you resolve it**, `<!-- -->` wrapper and worked example
included — a future session cannot tell the template's `docker compose up` from a real rule. Leave
everything not marked `FILL IN` alone: the model, the workflow, the task states and the conventions
are the system itself, not project settings.

In `CLAUDE.md`, and replace `<PROJECT>` in the title with the real name:

- **Block 1, environment.** Imperative, naming the actual commands, and saying what to do *instead*
  ("hand off the exact command and the log markers for success and failure"). "Run everything" →
  delete it; never write a rule that permits everything.
- **Block 2, repo layout.** The table only if work genuinely spans repos, with the branch column
  **dated** (`Branch (as of <YYYY-MM-DD>)`) and the 3–5 key paths. Single repo → delete.
- **Block 3, filing issues.** Tool and host, who owns the credential, the per-issue confirmation
  rule, the target project, and the label rules from §2: the kind labels, and which labels a
  workflow derives so nobody passes them by hand. No tracker → delete.
- **Block 4, files outside your scope.** The paths, and the pointer to `hotfixes.md` for per-file
  disposition, or to the `TEMPORARY (` marker at the site on a tracker-first install. Nothing
  off-limits → delete.
- **Block 5, review routing.** The paths-to-routes table, who merges, whether an agent may merge,
  and the branch pattern, in the words the user gave you. Never widen what they said: an invented
  "and code needs two approvals" is obeyed silently by every later session.
- **House style**, under Conventions: whatever the linter configs or `CONTRIBUTING.md` told you.

Then the other four: `comment_style.md`'s block (this project's comment conventions),
`bin/comment_audit.sh`'s (one `report` line per pattern this project bans), `bin/cloud_setup.sh`'s
(container setup commands, if any) and `bin/cloud_ready.sh`'s (the checks proving a container is
usable). With nothing to add, delete the block and say so.

**On `TRACKER_FIRST="yes"`, edit `CLAUDE.md` to match what `setup_apply.sh` removes**: the
`issues.md`, `hotfixes.md` and `deferred.md` rows in the persistent-docs table, and the wording
elsewhere that sends work to them (the plan-size rules, the conventions bullet on flagging temporary
work, the memory section's list). What replaces them is already written in that file's
"Tracker-first" paragraph: findings are reported and then filed, one place per filed issue, and
temporary code is a `TEMPORARY (<date>)` comment plus the issue whose `Done when:` removes it.

## 5. Hooks, style and the optional pieces

Read `.claude/hooks/README.md` and offer only what now applies, **one `AskUserQuestion` per hook**:

- **Block dangerous commands** — whenever the environment answer was anything but "run everything",
  and **build its pattern from the commands they named**: the difference between a rule written
  down and a rule that holds.
- **Show hotfixes before editing owned files** — only if block 4 was filled in, with their paths.
  On a tracker-first install the same hook prints that file's `TEMPORARY (` markers instead.
- **Session-start brief** — offer always. Cheap, and it makes stale `[~]` items visible.
- **`pull_main.sh`** — only when `MACHINES="multi"`, wired *before* the brief so the brief reflects
  what the other machine pushed. On one machine it can never find anything; don't offer it.
- **The cloud pair** — when `MACHINES="multi"`, say that `bin/cloud_setup.sh` and
  `bin/cloud_ready.sh` are run by hand on a fresh container. Neither is a hook.

Merge accepted hooks into `.claude/settings.json`, keeping the backup hooks and the attribution
block there, then verify with `python3 -m json.tool .claude/settings.json`: a malformed file
silently disables every hook in it.

**A cloud environment**, when `MACHINES="multi"`: print the two lines such an environment's setup
script wants, and say they run **per session, not per machine**, because the container is rebuilt
each time and reclaimed after inactivity:

```bash
[ -d .claude/skills ] || git clone --quiet <DOCS_REPO_URL> .claude
exec .claude/bin/cloud_env_setup.sh <owner-dir>
```

**Comment audit.** Say once that `.claude/bin/comment_audit.sh <file>` reports the comment shapes
`comment_style.md` rules out, is run by hand before a comment-heavy change, and grows this project's
own patterns in the block you resolved above. Then move on: it is not a hook and not a gate.

**Response style.** `.claude/output-styles/concise.md` ships with every install and nothing else
mentions it, so ask once: it caps explanation at about six lines and skips narration. If yes, set
`outputStyle` in `settings.local.json` — **not** `settings.json`, which is shared.

**Codex.** `codex/` bridges the same workflows to Codex and is inert unless `codex/install.sh` runs,
but an unrecognised directory is still something a reader has to rule out. Ask; if no,
`git -C .claude rm -qr codex`, restorable from that commit. If yes, say it installs per clone per
machine and `check_bridge.sh` runs after any skill is added, removed or renamed.

**The meeting loop — only when `PEOPLE="shared"`, and only if the team actually sits down together
on a schedule.** Ask; never assume it from `shared`. If yes, move the three `skills-optional/`
directories into `skills/` and `mkdir -p .claude/work/meetings`; if not, leave them where they are
and say they can be moved later. Either way `work/pipeline_backlog.md` stays — the meeting skills
*process* it, they don't justify it.

## 6. Apply the configuration

```bash
.claude/bin/setup_apply.sh            # --dry-run first if you want to see the plan
```

It reads `project.conf` and reports one line per step: makes the project ignore `.claude/`, writes
the project's root `CLAUDE.md` from `root_CLAUDE.md.example` (the only file that still loads when
`.claude/` is missing, which no hook can report), removes on `PEOPLE=solo` what describes
coordination between people, removes the three work files on `TRACKER_FIRST=yes`, installs and
verifies the union merge driver on `PEOPLE=shared`, copies the GitHub workflow where that applies,
and makes the scripts executable. It refuses if `.claude/` is not a clone with an `origin`, and
**leaves an existing root `CLAUDE.md` alone**, printing the pointer block instead: show the user
where to add it, or append it under a new heading. Every removal is a `git rm`, so the commit you
are about to make is also what restores any of it.

**On `PEOPLE="solo"`, edit `CLAUDE.md` to match what the script removed**, or it keeps describing
files that are gone: the `collab.md` and `collab_settled.md` rows, the whole **"More than one person
uses this `.claude/`"** section including **"Formatting for union merge"**, and the `work/owners.txt`
row, shortening the `PEOPLE` paragraph to say live tasks are at `work/current/`. `/add-person`
restores all of it from the commit you are about to make, which is why the removal is committed.

On `PEOPLE="shared"`, state the trade once: **union merge never conflicts**, so a genuine collision
merges silently and interleaved — which is why it covers only the append-only docs, and why
`CLAUDE.md`'s "Formatting for union merge" rules stay. `optional/github/CODEOWNERS` goes in the
**code** repo's root, and where it is a paid feature it is ignored in silence, so the reviewer
workflow is the half to rely on.

`TEMPLATE.md`, `test.sh` and the CI files are the template's own scaffolding — offer to delete them.

## 7. Commit, then report

```bash
git -C .claude add -A
git -C .claude commit -m "Configure this .claude/ for <project>"
```

**The `.claude/` repository only, and no push** — a narrow exception to "don't commit or push unless
asked", alongside `/save`'s. The solo and tracker-first removals are what `/add-person` or a change
of mind restores from, so leaving them uncommitted breaks the undo path exactly when someone needs
it; not pushing leaves a look first.

Then report, short: what each block says now, which you deleted and why, which hooks are live, what
went into the commit, and **both switches explicitly**, each with its visible consequence:

> `PEOPLE=shared` — live tasks go in `work/<you>/current/`, and the append-only docs union-merge.
> `MACHINES=multi` — `/save` stamps the machine and pushes; `/load` stops if the two diverge.

They silently change what every later session does, and now is the moment to correct a wrong one.
Name `TRACKER_FIRST` beside them where it is `yes`, with the three files it removed. Finish by
pointing at `/start`.

## Constraints

- **Run once.** Step 0 is a real gate, not a formality.
- **Never invent a rule the user didn't agree to** — an unasked-for constraint in `CLAUDE.md` is
  obeyed silently by every future session. Unsure? Delete the block: an absent rule is visible, a
  wrong one is not.
- Don't write entries in `decisions.md`, `traps.md` or the other work files, and don't write a plan:
  `/start` needs an objective agreed with the user that `/setup` cannot know.
