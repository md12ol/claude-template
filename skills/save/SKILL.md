---
name: save
description: Save the current session state into the .claude/ working docs — sweep the conversation for loose threads, update current/plan.md progress, append new decisions to decisions.md, log team issues to issues.md and temporary code to hotfixes.md, append a session entry to current/history.md, and write the next-session prompt to current/handoff.md. Use when the user asks to save, wrap up, checkpoint, or hand off the session.
---

# Save

Persist this session into the `.claude/` working docs so the next session — or a teammate — can pick
up cleanly. The point of running this *in-conversation* is that you can see the **rationale**, which
a cold reader cannot reconstruct. Use the live conversation for the "what and why"; use git for the
mechanical state.

If arguments were passed, narrow the save to that focus (e.g. "just the teardown work"); otherwise
cover everything since the last save.

## 0. Resolve where work lives — read it, do not assume it

Live task paths depend on how this `.claude/` is configured. **Read the configuration; never guess
from what is on disk.**

```bash
. .claude/hooks/lib.sh && load_conf && resolve_owner
echo "$WORK_CURRENT"      # work/current  OR  work/<owner>/current
echo "$WORK_PARKED"       # work/parked   OR  work/<owner>/parked
```

On a **shared** install the owner comes from `git config user.email` matched against
`work/owners.txt` — **the only copy of that table**. An empty `WORK_CURRENT` means the address is
not in it: **stop and ask**, never pick the likeliest person. Writing into someone else's directory
is silent, and surfaces only when they open a directory they didn't expect to have work in.

Everything below writes `$WORK_CURRENT` and `$WORK_PARKED`, so the same instructions hold either
way. **Every `work/` path is inside the `.claude/` repository**, not the branch this session is
coding on — it is a clone with one branch of its own. Pull it first:

```bash
git -C .claude pull --ff-only
```

The main tree's checked-out branch is never switched, stashed or touched.

## The files

All live under `.claude/`.

**Task-scoped**, in `.claude/$WORK_CURRENT/` — archived by `/done` when the task ends:

| File | Semantics | Holds |
|---|---|---|
| `$WORK_CURRENT/plan.md` | **Edit in place** | Current objective + task list with status. Written by `/start`; `save` only updates status and appends newly-agreed work. |
| `$WORK_CURRENT/plan_superseded.md` | **Append-only** | Original wording of tasks now done. Reference only. |
| `$WORK_CURRENT/history.md` | **Append-only** | Session-by-session log for *this task*, newest first. |
| `$WORK_CURRENT/handoff.md` | **Overwritten** | A prompt for the *next* session. Only the newest matters. |

**Persistent**, at `.claude/` — these outlive the task, because they describe the *code*, not the
work. Never archive them:

| File | Semantics | Holds |
|---|---|---|
| `decisions.md` | **Append-only** | Every choice made and why. Never edit or delete a past entry. |
| `issues.md` | **Churn list** | Work for other people, staged for the tracker. Entries leave only once filed. |
| `hotfixes.md` | **Churn list** | Temporary / band-aid code in the tree. Entries leave only once reverted. |
| `traps.md` | **Churn list** | Permanent workspace gotchas. Entries leave only when no longer true. |
| `traps_retired.md` | **Append-only** | Traps whose cause has been fixed, each naming the fix. |
| `deferred.md` | **Churn list** | Wanted, deliberately not now. Entries leave when the tracker takes them. |
| `collab.md` | **Append-only** | Cross-owner decisions, when the repo is shared. Agreed items are marked, never deleted. Skip if the file doesn't exist. |

## 1. Gather state

- `git status --short` and `git diff --stat` for **every repo this project spans** — see `CLAUDE.md`'s
  repo layout, and don't assume the root repo is the only one.
- Report each repo's current branch (`git branch --show-current`). Read the actual branch, never
  assume.
- Read `$WORK_CURRENT/plan.md`, and the tops of `decisions.md`, `issues.md`, `hotfixes.md`, `traps.md`, so
  you match their format and don't duplicate existing entries.

## 2. Sweep the session for loose threads

**Do this before writing anything.** Re-read the conversation since the last save and list what was
**discussed but never landed**. Only an in-conversation save can: the docs know what was *written*,
and the failure mode is something agreed out loud and dropped when the conversation moved on. The
single highest-value step here.

Look for:

- **Agreed, then diverted** — you proposed something, the user approved it, and neither of you came
  back to it. The signal is an approval ("yes", "go ahead") with no later result.
- **Found in passing** — a bug or gap you noticed while doing something else and mentioned in prose,
  but never turned into a plan task, issue, or hotfix entry.
- **Asked and unanswered** — a question you put to the user that the next message overtook.
- **Recommended, no verdict** — you advised something and the user neither took it nor refused it.
- **The user took it on** — anything they said *they* would do. Record it, or explicitly drop it;
  never silently assume it happened.
- **Corrections with reach** — a mid-session correction that invalidates something already written
  in a doc, a plan item, or an earlier claim. Fix the doc; don't just note the correction.
- **Numbers that moved** — a measurement or estimate that changed. Anything quoting the old value
  has to be updated too.
- **Work started but not finished** — a file half-edited, a check run but not acted on.
- **New traps** — anything that cost you time this session and will cost it again: a tool flag that
  must always be passed, a command that silently does the wrong thing, a path that isn't what it
  looks like. → `traps.md`.
- **Wanted, ruled out for now** — something you both agreed was worth doing and out of scope for
  this milestone. → `deferred.md`, which is where it stops being remembered only by you.

Then dispose of every item, strictly:

- **Can be captured now** → write it into the right file in the steps below (plan task, decision,
  issue, hotfix, trap). Actually do it — don't just report it.
- **Needs the user** → **ask.** See below. **Never guess a disposition and record it as though it
  were agreed.**

Don't pad the list. If a thread genuinely resolved, leave it off. Its value is that every line on it
is real.

### Ask the open ones as a series of questions

Put the threads that need the user through `AskUserQuestion` — **one question per thread**, batched
up to 4 per call, repeating until all are answered. Never bury them in a prose list: a bullet in a
closing summary is easy to skim past, and these are exactly the items that vanish on `/clear`.

For each question:

- State the thread in the question text, with enough context to answer cold — the user may have
  discussed it an hour and several topics ago.
- Give real options, each with what it actually costs or implies. Lead with a recommendation where
  you have one, marked `(Recommended)`.
- Where the choice is "do it now / write it down / drop it", say so plainly — *drop it* is a
  legitimate answer and should be offered, not smuggled in as an afterthought.

Then act on every answer **before** finishing the save: write the resulting task, decision, issue or
hotfix entry, so the answers land in the files rather than only in the transcript.

Ask only about genuine forks. Anything you can settle by reading the repo, or that has an obvious
default, you settle yourself and mention in the closing brief.

## 3. `$WORK_CURRENT/plan.md` — update status

- Mark completed items. Use three states, and keep them honest:
  `[ ]` pending · `[x]` done **and verified** · `[~]` done but **NOT verified**.
- `[~]` is the important one: code that only compiles, or that ran only somewhere that doesn't
  count, is `[~]` — not `[x]`. Say what verification is still owed, and **stamp it**:
  `(unverified since <YYYY-MM-DD>)`. Age is what makes a stale `[~]` visible as stale.
- **Compress each item as you tick it — to ≤ 3 lines.** What was done, the one piece of evidence,
  where the detail lives. Evidence goes to `history.md`, reasoning to `decisions.md`. Original
  wording worth keeping moves to `$WORK_CURRENT/plan_superseded.md` under a
  `## <item id> — superseded <YYYY-MM-DD>` heading.
- Append work agreed *during* this session that isn't yet on the plan, including whatever the
  step-2 sweep turned up.
- Strike items that were abandoned, with a one-line reason (and a matching `decisions.md` entry).
- Do not restructure or rewrite the plan's existing items.

### Keep the plan a TASK LIST, not a record — enforce this every save

Left unenforced it grows without bound; in the project this template came from it reached 1432 lines
and had to be halved by hand. It grew because evidence, rationale and superseded text accumulated in
it, and each of those has a file that owns it:

| What | Where it goes | NOT in the plan |
|---|---|---|
| What happened, measurements, tables | `$WORK_CURRENT/history.md` | ✗ |
| Why we chose it, what was rejected | `decisions.md` | ✗ |
| Original wording of a task now done | `$WORK_CURRENT/plan_superseded.md` | ✗ |
| Temporary code | `hotfixes.md` | ✗ |
| Someone else's work | `issues.md` | ✗ |

**Budgets — check at every save, fix on the spot:**

- **Completed item ≤ 3 lines**, per the compression rule above.
- **Open item ≤ 20 lines** — what to do, the verify-by, and any constraint that causes harm if
  forgotten. More than that, and the reasoning goes in `decisions.md` with the plan linking to it.
- **Never leave a superseded item wearing a `[ ]`.** An item that can never be ticked teaches
  everyone to skim past `[ ]`, and then a real pending item gets lost.
- **Soft cap ~600 lines** (`wc -l $WORK_CURRENT/plan.md`, as part of the save). Over it, compress the
  biggest completed items before appending new ones.
- **Amalgamate** two items describing the same work — a task and its "verification" twin, an item
  and its rewrite — keeping the number referenced elsewhere.

## 4. `decisions.md` — append what was chosen and why

One entry per real decision, appended at the **bottom**. Never edit a past entry: if this session
reversed an earlier decision, write a NEW entry that names and supersedes it. The reversal trail is
the value.

```markdown
## <YYYY-MM-DD> — <author> — <short title>
**Chose:** what we're doing.
**Why:** the reasoning, in the terms it was actually argued.
**Rejected:** the alternatives considered, and what ruled them out.
**Affects:** `path:line`, or the area it constrains.
**Supersedes:** <date + title of the earlier decision>   (only if applicable)
```

Only log decisions a cold reader couldn't re-derive from the code. Skip the obvious.

Drop the `— <author>` field if you work alone. Keep it if anyone else uses this `.claude/`:
the persistent docs merge with `merge=union`, which never reports a conflict, so the stamp is
the only thing that makes an accidentally duplicated entry visible.

## 5. `issues.md` — stage work for other people

Anything found this session that belongs to someone else, or is out of scope for the current work.
The file has **two tiers**, and the distinction is whether it has been root-caused.

**Parked** — noticed, not investigated. Cheap to write, so nothing is lost just because chasing it
would derail the current task. Four lines, no more:

```markdown
### <what was noticed>
- **Where:** `path` or component, as far as it's known.
- **Impact:** why it matters — who or what it breaks.
- **Noticed:** <YYYY-MM-DD>, in <what you were doing when you hit it>
```

**Ready to file** — root-caused and evidenced, written so the body pastes into the tracker
unchanged. How issues get filed lives in `.claude/CLAUDE.md`.

```markdown
### <title — imperative, issue-ready>
- **For:** teammate / team / unassigned
- **Project:** the tracker project it belongs to
- **Filed:** not yet          ← becomes the issue URL once filed
- **Component:** `path:line` (the specific module/function)
- **Body:**
  What's wrong, the mechanism with `path:line`, evidence (rates, run IDs, measurements),
  how to reproduce, and the candidate fixes.
```

Promote parked → ready only when the investigation actually happened. **Never fabricate evidence
fields to make something look file-ready** — a guess dressed as a root cause wastes the assignee's
time. Once filed, **the tracker is the source of truth**: later changes go there in the same
session, and `issues.md` must not become a private fork of it.

Drop entries whose **Filed** is a URL and whose issue is closed. Leave everything else.

## 6. `hotfixes.md` — track temporary code

Every band-aid, stub, sleep, hardcoded value, or workaround still in the tree. Each entry needs an
exit condition, or it lives forever:

```markdown
### <what was hacked>
- **Owner:** who put it there and who removes it. Omit if you work alone.
- **Machine:** `owner's working tree, uncommitted` · `committed — in every tree` · `branch <name>`.
  Omit if you work alone; otherwise this is what tells a reader whether it is in *their* tree.
- **Where:** `path` or symbol name — prefer function names over line numbers, they survive edits.
- **What it does:** the mechanism, if not obvious from the title. Optional.
- **Why it's a hotfix:** the problem it papers over, and why the proper fix wasn't done here.
- **Real fix:** what would make this unnecessary, and **who owns it** if it's someone else.
- **Remove when:** the concrete condition that makes it unnecessary.
- **Added:** <YYYY-MM-DD>
- **Last checked:** <YYYY-MM-DD> — set by `/done`, not by `/save`. Shows when the `Remove when:`
  condition was last assessed, so a stale entry is visible as stale.
```

Group entries under `## <theme>` headings by what unblocks them (e.g. shared infra, upstream,
someone else's work) — that's the axis on which they actually get removed, in batches.

Mark any hotfix that is currently **load-bearing** (something would break today without it) with
⚠️ in its `Remove when:`, so nobody deletes it on a tidying pass.

If a hotfix in someone else's file must never be committed, say so **in the entry**, not only in the
plan — that entry is what a future session reads before touching the file.

Remove entries whose hotfix is genuinely gone from the tree — verify by reading the file, don't
assume.

## 7. `traps.md` — permanent workspace gotchas

Distinct from hotfixes: a hotfix is *code you added and want to remove*; a trap is *how this
workspace behaves and always will*. Tool flags that must always be passed, commands that silently do
the wrong thing, paths that aren't what they look like, files that a routine command will delete.

```markdown
### <the trap, stated as the mistake it prevents>
- **Bites when:** the action that triggers it.
- **Do this instead:** the correct form.
- **Why:** the mechanism, one line.
- **Added:** <YYYY-MM-DD>
```

These belong here rather than in `handoff.md`. `handoff.md` is overwritten every save, so anything
durable parked there is deleted the moment it stops being top-of-mind.

**Verify a trap before recording it.** Traps are stated as fact and trusted for months. Run the
reproducer and put it in the entry — in the project this came from, a `grep` trap sat in
`handoff.md` for days with the wrong mechanism before anyone re-tested it.

**Retire, don't delete.** If this session removed a trap's cause, move the entry to
`traps_retired.md` with a `Fixed by:` line naming the change — revert that fix and the trap is back
exactly as written. Delete outright only when the mechanism is gone for good: the file removed, the
tool dropped, the platform changed under it.

## 8. `$WORK_CURRENT/history.md` — append a session entry

Insert `## Session <YYYY-MM-DD>: <one-line headline>` at the **top** of the session log —
after the header/goals block at the top of the file and before the previous most-recent session
section. Do not rewrite old sections; if a past section's status changed, add a
one-line `UPDATE <YYYY-MM-DD>:` note to it.

Contents: what changed (with `path:line`), what was validated vs. not, and the **git manifest** —
exact uncommitted/unpushed state per repo and branch, so nothing is lost. Keep the reasoning short
here; let `decisions.md` carry it.

## 9. `$WORK_CURRENT/handoff.md` — write the next-session prompt

Overwrite the whole file. This is not a summary — it is an **instruction to the next session**,
written so that pasting it is enough to resume. Address it to the agent, second person, imperative:

```markdown
# Next session — <YYYY-MM-DD>
**Machine:** <hostname> · saved <YYYY-MM-DD HH:MM> · <SHA the save was written against>

Read `.claude/$WORK_CURRENT/plan.md` and `.claude/work/decisions.md` first, then `.claude/work/hotfixes.md`.

**Where things stand:** 2–4 sentences.

**Start here:** the single next concrete action, with the file and the command to run.

**Watch out for:** live traps — unverified `[~]` items, hotfixes that will bite, known-broken state.

**⏰ Time-sensitive:** anything dated, with absolute dates.
```

**Keep it to what is true this week.** If you are about to write something permanent here — a tool
flag that always applies, a rule about how to write issues, a path that a routine command destroys —
it belongs in `traps.md` or `CLAUDE.md` instead. This file is overwritten every save; anything
durable left in it is on a timer.

**One `Start here`.** If there is genuinely a queue, name the single next action, then list the rest
under a separate "then, in priority order" heading — so the next session cannot mistake the queue
for the instruction.

### The `Machine:` stamp — only on a multi-machine install

Include it when `project.conf` says `MACHINES="multi"`; omit the line entirely otherwise, rather
than writing a stamp nobody will read.

```bash
echo "**Machine:** $(hostname -s) · saved $(date '+%Y-%m-%d %H:%M') · $(git rev-parse --short HEAD)"
```

The hazard on a multi-machine install is **you versus you**. Two machines editing one `plan.md` is a
real conflict on a file rewritten in place, and no merge strategy recovers the intent. The stamp is
what lets `/load` §0.6 notice before anything is trusted — it stops and reports rather than merging.

## Union-merge safety — check before you finish

If the repo is shared and `.gitattributes` sets `merge=union` on `.claude/work/*.md`, a byte-identical
line in two entries is folded together on merge and the entries interleave — silently. Every entry
you appended this save must have a **unique first and last line**: a heading carrying the author,
and a closing stamp carrying a time, e.g. `*#7 · raised <YYYY-MM-DD> <HH:MM> — <name>.*`

Run this on every file you touched, and fix anything it prints:

```bash
grep -vE '^\s*$' .claude/work/<file>.md | sort | uniq -d
```

Bare labels are the usual culprit — `- **Body:**`, `- **Added:** <date>`, a trailing `---`.

## Conventions

- **Absolute dates only** — convert "today" / "tomorrow" / "last session" to real dates.
- Reference code as `path:line`. Keep it skimmable: headers and bullets, not walls of prose.
- If tooling or output behavior changed, check the run instructions in `$WORK_CURRENT/plan.md` and
  `$WORK_CURRENT/history.md` still match, and fix them if not.
- Never truncate or rewrite `$WORK_CURRENT/history.md` or `decisions.md`.
- **If anyone else uses this `.claude/`:** stamp every new entry in the persistent docs with an
  author, and never silently rewrite someone else's entry — raise it in `collab.md` instead.
  If this session merged, read the tail of the persistent docs before appending: `merge=union`
  can interleave two entries without reporting a conflict.

## Memory — do not use it for this project

**Do not write auto-memory files.** See `.claude/CLAUDE.md`, "Do not use the auto-memory store".

Durable project facts go in the file that owns that lifetime — `hotfixes.md`, `issues.md`,
`traps.md`, `decisions.md`, `$WORK_CURRENT/history.md`, `$WORK_CURRENT/plan.md`. A rule about *how to work* that
must be known before reading any of them goes in `CLAUDE.md`.

## 10. Commit and push the live task directory — part of the save, not a follow-up

**Only `$WORK_CURRENT` and `$WORK_PARKED`, and only when they are tracked.** This is a deliberate,
narrow exception to "don't commit or push unless asked", and it does not widen: source code, the
persistent docs and any design document each still need their own explicit instruction, every time.
A `/save` that finds uncommitted source **leaves it alone and says so**.

Skip this step entirely when the live task directory is gitignored — on a solo single-machine
install that is the normal, correct configuration.

```bash
git -C .claude add "$WORK_CURRENT" "$WORK_PARKED" 2>/dev/null
git -C .claude commit -m "save: <task slug> — <what moved>"
git -C .claude push
```

The directory is tracked precisely so the task resumes on another machine, and **a save that never
reaches `origin` fails silently** — you find out there, usually a day late. Pushing is the point of
tracking it.

If the push is rejected, **do not force it.** Report and stop: it usually means the other machine
saved first, which is the divergence `/load` §0.6 exists to catch, and resolving it needs a human
looking at both plans.

## 11. Close with a brief the user can answer

End with a short summary — **not** a file-by-file changelog. Its job is to surface what is
outstanding, so nothing rots quietly between sessions. Under ~20 lines.

The step-2 threads have already been asked, answered and written into the files by this point. The
brief reports what came of them; it does not re-litigate them.

```markdown
**Saved:** <one line — what this session actually did>

**Settled this save:** <one line per loose thread the questions resolved, and where it landed>

**Outstanding**
- ⚠️ <N> issues unfiled: <titles>            ← only if any are `Filed: not yet`
- ⚠️ <N> hotfixes still in the tree: <the ones touched or relied on this session>
- <N> `[~]` unverified, oldest first: <what needs running, by whom, and since when>
- <blockers / open questions from plan.md>

**Next session starts at:** <the one action in handoff.md>
```

Rules for this brief:

- **Only list what's genuinely outstanding.** Nothing unfiled and nothing unverified? Say so in one
  line — a brief that always looks the same gets skipped.
- Unfiled issues and unverified `[~]` items go **first**; those two go stale silently.
- List the hotfixes this session added, touched or leaned on, not all of them every time.
- Make each line answerable: name the thing, say what it's waiting on.

The user may reply with dispositions ("file that one", "that one can wait"). Act on them and update
the docs before finishing.

## 12. Offer to clear the context

End by asking — **never do it yourself, and never assume the answer:**

> Everything is captured in the docs. Want to `/clear` and start fresh? Next session picks up with
> `/load`.

`/clear` is a CLI command only the user can type; you cannot run it and must not try. A save is the
one moment when clearing is safe, because the state now lives in the files and `handoff.md` is
written to resume from cold. Mid-task they will often decline — ask once, take the answer, don't
press.

### If work continues after the save, the save is stale

A save is a snapshot, not a seal. **Any work done after the brief is not in the docs**, and it bites
specifically: the brief and `handoff.md` are written as though the session ended there, so they can
actively *mislead* the next session by pointing at a state that has moved on. When work continues:

- **Keep updating the docs as you go** — a decision made after the brief belongs in `decisions.md`
  when it is made, not banked for a second save.
- **Re-run `/save` before `/clear`** or before the session ends. It is cheap: step 2 sweeps only
  what happened since, and most files need no change.
- **Re-check `handoff.md`.** It is written about a "next session" that may now start somewhere else:
  verify its *Start here* is still the real next action and names nothing the later work deleted.

The step-2 sweep catches threads *within* a save. Nothing catches work done *after* one except
saving again.

## Constraints

- **Commit and push nothing but `$WORK_CURRENT` and `$WORK_PARKED`, per §10.** Source code, the
  persistent docs and any design document each need their own explicit instruction, every time.
- After the brief, report per file what you added, or that it was unchanged.
