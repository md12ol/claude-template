---
name: save
description: Save this session into the .claude/ working docs — sweep the conversation for loose threads, update the plan, append what was decided and learned, and write the next-session handoff. Use when the user asks to save, wrap up, checkpoint or hand off the session.
---

# Save

Persist this session into the working docs so the next session — or a teammate — picks up cleanly.
The point of running it *in-conversation* is that you can see the **rationale**, which a cold reader
cannot reconstruct: use the conversation for the what and why, and git for the mechanical state.

If arguments were passed, narrow the save to that focus ("just the teardown work"); otherwise cover
everything since the last save.

## 0. Where work lives

```bash
eval "$(.claude/bin/task.sh paths)" && .claude/bin/task.sh pull
```

Both paths are inside the `.claude/` repository, never the branch you are coding on. On a shared
install an unrecognised git email stops here — ask whose it is, never guess.

## 1. Gather state

- `git status --short` and `git diff --stat` for **every repo this project spans** — see
  `CLAUDE.md`'s repo layout; don't assume the root repo is the only one.
- Each repo's branch, read with `git branch --show-current`, never assumed.
- `$WORK_CURRENT/plan.md`, and the tops of `decisions.md`, `issues.md`, `hotfixes.md` and
  `traps.md`, so you match their format and don't duplicate an entry that is already there.

## 2. Sweep the session for loose threads

**Do this before writing anything**, and treat it as the highest-value step here. Re-read the
conversation since the last save and list what was **discussed but never landed**. Only an
in-conversation save can: the docs know what was *written*, and the failure is something agreed out
loud and dropped when the conversation moved on.

- **Agreed, then diverted** — you proposed it, the user approved it, neither of you came back. The
  signal is an approval with no later result.
- **Found in passing** — a bug or gap you noticed while doing something else and mentioned in prose,
  never turned into a task, issue or hotfix entry.
- **Asked and unanswered** — a question to the user that the next message overtook.
- **Recommended, no verdict** — you advised something and it was neither taken nor refused.
- **The user took it on** — anything they said *they* would do. Record it or explicitly drop it;
  never silently assume it happened.
- **Corrections with reach** — a mid-session correction that invalidates something already written
  in a doc or a plan item. Fix the doc; don't just note the correction.
- **Numbers that moved** — a measurement or estimate that changed, and anything quoting the old one.
- **Work started but not finished** — a file half-edited, a check run but not acted on.
- **New traps** — anything that cost you time this session and will cost it again. → `traps.md`.
- **Wanted, ruled out for now** — agreed worth doing, out of scope for this milestone.
  → `deferred.md`, where it stops being remembered only by you.

Then dispose of every item, strictly. **Can be captured now** → write it into the right file in the
steps below; actually do it, don't just report it. **Needs the user** → ask, below. Never guess a
disposition and record it as though it were agreed. Don't pad the list either: if a thread genuinely
resolved, leave it off. Its value is that every line on it is real.

### Ask the open ones as a series of questions

Put every thread that needs the user through `AskUserQuestion` — **one question per thread**,
batched up to 4 per call, repeating until all are answered. Never bury them in a prose list: a
bullet in a closing summary is easy to skim past, and these are exactly the items that vanish on
`/clear`.

- State the thread in the question text, with enough context to answer cold — the user may have
  discussed it an hour and several topics ago.
- Give real options, each with what it costs or implies. Mark a recommendation `(Recommended)`.
- Where the choice is "do it now / write it down / drop it", say so plainly. *Drop it* is a
  legitimate answer and is offered, not smuggled in as an afterthought.

Act on every answer **before** finishing the save, so it lands in a file rather than the transcript.
Ask only about genuine forks: anything with an obvious default you settle yourself and mention in
the closing brief.

## 3. `$WORK_CURRENT/plan.md` — update status

- Mark completed items honestly: `[ ]` pending · `[x]` done **and verified** · `[~]` done but **NOT
  verified**.
- `[~]` is the important one. Code that only compiles, or ran only somewhere that doesn't count, is
  `[~]`. Say what verification is still owed and **stamp it** `(unverified since <YYYY-MM-DD>)` —
  age is what makes a stale `[~]` visible as stale.
- **Compress each item as you tick it.** Evidence goes to `history.md`, reasoning to `decisions.md`,
  and original wording worth keeping moves to `plan_superseded.md` under a
  `## <item id> — superseded <YYYY-MM-DD>` heading. Budgets and the soft cap are in `CLAUDE.md`,
  "Keep `plan.md` small" — check them at every save and fix on the spot, amalgamating two items that
  describe the same work.
- Append work agreed *during* this session, the step-2 sweep included, and strike what was abandoned
  with a one-line reason and a matching `decisions.md` entry.
- Never leave a superseded item wearing a `[ ]`, and do not restructure the plan's existing items.

## 4. `decisions.md` — what was chosen and why

One entry per real decision, appended at the **bottom**, matching the template at the top of the
file. Only log what a cold reader could not re-derive from the code. **Never edit a past entry:** if
this session reversed one, write a new entry that names and supersedes it — the reversal trail is
the value.

## 5. `issues.md` — work for other people

Anything found this session that belongs to someone else or is out of scope. Two tiers, per the
templates at the top of the file: **parked** (noticed, not investigated — cheap to write, so nothing
is lost just because chasing it would derail the task) and **ready to file** (root-caused and
evidenced, so the body pastes into the tracker unchanged). Promote parked → ready only when the
investigation actually happened, and **never fabricate an evidence field** to make something look
file-ready. Once filed, the tracker is the source of truth and this file must not fork it: drop
entries whose issue is closed, and put later changes in the tracker the same session.

## 6. `hotfixes.md` — temporary code in the tree

Every band-aid, stub, sleep, hardcoded value and workaround still in the tree, matching the template
at the top of the file. Each needs a concrete `Remove when:` or it lives forever. Mark anything
load-bearing ⚠️ so nobody deletes it on a tidying pass, group entries by what unblocks them, and if
a hotfix in someone else's file must never be committed, say so **in the entry** — that is what a
future session reads before touching the file. Remove entries whose code is genuinely gone, verified
by reading the file rather than assumed.

## 7. `traps.md` — permanent workspace gotchas

A hotfix is *code you added and want to remove*; a trap is *how this workspace behaves and always
will* — a flag that must always be passed, a command that silently does the wrong thing, a path that
is not what it looks like. Match the template at the top of the file.

**Verify a trap before recording it.** They are stated as fact and trusted for months, so run the
reproducer and put it in the entry. They belong here rather than in `handoff.md`, which is
overwritten every save.

**Retire, don't delete.** If this session removed a trap's cause, move the entry to
`traps_retired.md` with a `Fixed by:` line naming the change — revert that and the trap is back
exactly as written. Delete outright only when the mechanism is gone for good.

## 8. `deferred.md` — wanted, deliberately not now

Where a "yes, but not this milestone" goes, so it stops living in one person's head. An entry names
the change and what would have to be true to admit it; no dates, no ordering, no priority, or it
becomes a second build order competing with the tracker. Anything with a shape someone would
plausibly start this month is an issue instead.

## 9. `$WORK_CURRENT/history.md` — append a session entry

Insert `## Session <YYYY-MM-DD>: <one-line headline>` at the **top** of the log — after the header
block, before the previous session. Don't rewrite old sections; if a past one's status changed, add
a one-line `UPDATE <YYYY-MM-DD>:` note to it.

Contents: what changed with `path:line`, what was validated and what was not, and the **git
manifest** — exact uncommitted and unpushed state per repo and branch, so nothing is lost. Keep the
reasoning short; `decisions.md` carries it.

## 10. `$WORK_CURRENT/handoff.md` — write the next-session prompt

Overwrite the whole file. This is not a summary; it is an **instruction to the next session**,
written so that pasting it is enough to resume. Address the agent, second person, imperative.

```markdown
# Next session — <YYYY-MM-DD>
<the output of `.claude/bin/task.sh stamp`, when it prints anything>

Read `$WORK_CURRENT/plan.md` and `work/decisions.md` first, then `work/hotfixes.md`.

**Where things stand:** 2–4 sentences.

**Start here:** the single next concrete action, with the file and the command to run.

**Watch out for:** live traps — unverified `[~]` items, hotfixes that will bite, known-broken state.

**⏰ Time-sensitive:** anything dated, with absolute dates.
```

`task.sh stamp` prints the `Machine:` line on a multi-machine install and nothing on a single one,
so it is there exactly when `/load`'s divergence check can use it. The hazard it guards is **you
versus you**: two machines editing one `plan.md` is a real conflict on a file rewritten in place,
and no merge strategy recovers the intent.

**Keep the file to what is true this week.** Anything permanent — a flag that always applies, a path
a routine command destroys — belongs in `traps.md` or `CLAUDE.md` instead; this file is overwritten
every save, so anything durable left here is on a timer. **One `Start here`**: if there is genuinely
a queue, name the single next action and list the rest under "then, in priority order", so the next
session cannot mistake the queue for the instruction.

## 11. Audit, then commit and push

```bash
.claude/bin/task.sh audit
.claude/bin/task.sh commit "save: <slug> — <what moved>"
```

`audit` checks the union-merged docs for lines two entries could collapse onto — bare labels like
`- **Body:**`, a trailing `---`, a stamp with no time — and for `collab.md` headings a merge spliced
mid-line. Fix anything it prints before committing: union merge never reports a conflict, so this is
the only thing that will tell you.

`commit` commits `$WORK_CURRENT` and `$WORK_PARKED` and pushes when the docs clone has an `origin`.
A save that never reaches `origin` fails silently — you find out on the other machine, usually a day
late. **On a rejected push, do not force it**: report and stop. It usually means the other machine
saved first, which is the divergence `/load` exists to catch, and resolving it needs a human looking
at both plans.

This is a deliberate, narrow exception to "don't commit or push unless asked" and it does not widen:
source code, the persistent docs and any design document each need their own explicit instruction,
every time. A `/save` that finds uncommitted source **leaves it alone and says so**.

## 12. Close with a brief the user can answer

Under ~20 lines, and **not** a file-by-file changelog. Its job is to surface what is outstanding, so
nothing rots quietly between sessions. The step-2 threads are already asked, answered and written in
by now; the brief reports what came of them and does not re-litigate them.

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

- **Only list what is genuinely outstanding.** Nothing unfiled and nothing unverified? Say so in one
  line — a brief that always looks the same gets skipped.
- Unfiled issues and unverified `[~]` items go **first**; those two go stale silently.
- List the hotfixes this session added, touched or leaned on, not all of them every time.
- Make each line answerable: name the thing, say what it is waiting on. The user may reply with
  dispositions ("file that one", "that can wait") — act on them and update the docs before finishing.

## 13. Offer to clear the context

End by asking — **never do it yourself, and never assume the answer:**

> Everything is captured in the docs. Want to `/clear` and start fresh? Next session picks up with
> `/load`.

`/clear` is a CLI command only the user can type. A save is the one moment when clearing is safe,
because the state now lives in the files. Mid-task they will often decline: ask once, take the
answer, don't press.

### If work continues after the save, the save is stale

**Any work done after the brief is not in the docs**, and `handoff.md` was written as though the
session ended there, so it can actively mislead the next session. When work continues: keep updating
the docs as you go, re-run `/save` before `/clear` or before the session ends (it is cheap — the
sweep covers only what happened since), and re-check that `handoff.md`'s *Start here* is still the
real next action and names nothing the later work deleted.

## Conventions

- **Absolute dates only** — convert "today", "tomorrow" and "last session" to real dates. Reference
  code as `path:line`. Keep it skimmable: headers and bullets, not walls of prose.
- Never truncate or rewrite `history.md` or `decisions.md`.
- If tooling or output behaviour changed, check that the run instructions in `plan.md` and
  `history.md` still match, and fix them if not.
- **On a shared install:** stamp every new entry in the persistent docs with an author and a time,
  and never silently rewrite someone else's entry — raise it in `collab.md` instead. If this session
  followed a merge, read the tail of those docs before appending.
- After the brief, report per file what you added, or that it was unchanged.
