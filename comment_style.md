# Comment style

**This binds every comment written or edited in this project.** It is short on purpose: the whole of
it reduces to one test and one habit, and everything else is that test applied to shapes that keep
recurring. Where this file and a comment in the tree disagree, this file is the intent; fix the
comment. It is deliberately language-neutral: answer the block at the end for your project, and
delete any section that does not apply to how your language actually works.

## 1. The test

**Would deleting this make a competent reader, new to *this code* rather than new to the field, more
likely to misunderstand or break it?**

No → delete it. That is the whole rule. **The default is no comment**; one line is the norm, a
second needs a reason a reader can act on, and limits are ceilings rather than targets. Your reader
knows the language, and knows what a hash map and a race condition are. They do not know why *this*
function takes the lock before reading the cache, or why *this* loop counts down. Write the second
thing, never the first.

## 2. Prefer removing the comment's reason to exist

The best outcome is not a tighter comment but code that no longer needs one. Prefer, in order:
**a clearer name · different structure · a validation or an assertion · a test · shipped
documentation · prose.**

A comment explaining what `d` holds is worse than renaming it; one warning that the caller must call
`init()` first is worse than a runtime check, or a type that makes it impossible; one describing the
three cases handled here is worse than three tests named after them. Reach for prose only when none
of the above can carry it: mostly for **why**, almost never for **what**.

## 3. What earns a comment

- **A reason not visible from the code.** Why this algorithm and not the obvious one, why this
  constant, why the order of these two lines matters. The most valuable comment there is, and the
  one most often missing.
- **A precondition the type system cannot express**: one line, stating the failure, not the rule:
  "panics if the slice is empty" beats "the slice must not be empty".
- **A caller-visible effect that is easy to miss**: a parameter mutated in place, a global touched.
- **A deliberate divergence from a sibling.** Where two similar functions differ on purpose, the odd
  one out says why, or the next person "fixes" it.
- **A workaround for someone else's bug**, with enough detail to retire it: what breaks, and what
  would have to change for this to go away. Cross-reference it where temporary code is tracked.

## 4. What to remove

- **Anything that narrates the next line** (`// increment the counter` above `counter += 1`), and
  anything that restates a name: if the comment is the name in a sentence, delete the comment.
- **Counts and roll-calls that rot.** "the three supported backends", "all five callers". Say "each
  backend", "every caller". A number is wrong the moment someone adds a sixth, and nothing tells you.
- **Commented-out code.** Version control already has it, with a date and an author.
- **A comment describing a state of the world**: "currently unused", "will be replaced next
  quarter". Say what the thing is *for*; that does not rot.
- **A pointer to a document the reader cannot open.** Shipped source citing an internal planning
  doc, a private tracker or a design file outside the repo is a dead end downstream: state the
  reason itself rather than where it was agreed.

## 5. How to write the ones that stay

- **Lead with the useful fact**; keep one idea beside the code it constrains, and **state the thing,
  then explain it, never alternating**: "the seed and the run index are recorded, so a run can be
  reproduced and traced", not "the seed is recorded so it can be reproduced, the run index is
  recorded so it can be traced". The alternating form recites the code line by line and lengthens
  every comment it touches.
- **An ordering claim names its key.** "In ascending order" says nothing about ascending by what.
  Write "sorted by start, then by id", or delete the claim. Same for "sorted", "ranked", "in order".
- **A claim that categorises what it lists must have the category right.** A category that is almost
  right reads as authoritative and is worse than the list it replaced. Name the groups instead.
- **A dependency claim is verified by opening the caller, never inherited.** A working doc, a design
  note and a neighbouring comment are all hearsay, and "does the body match the doc" passes on a
  wrong name; reading the call sites is what shows the mismatch.
- **A doc comment has a different audience from an inline one.** It is read by people who will never
  open this file, so it carries the caller-visible contract: errors, edge cases, the smallest useful
  example. Work out who reads an item before deciding its comment is redundant with a neighbour's.
- **One condition needs no section heading.** Structure a comment only once it has parts.

## 6. Extension markers

When adding a feature means touching several places in a fixed order, mark each site with a literal,
greppable token, `ADD A <THING> STEP <n>`, rather than describing the sequence in prose somewhere
else, so that one command finds every site at once:

```bash
git grep -nE "ADD AN? .* STEP [0-9]"
```

**The marker sits at the site that must change**, which is the point: a prose walkthrough lives away
from the code and drifts from it silently, while a marker is found by whoever is already editing.
**Where a chain forks, the marker names the fork:** `ADD A BACKEND STEP 3 (for streaming)` beside
`ADD A BACKEND STEP 3 (for batch)`, or a reader extending one path meets a numbered list mixing
their steps with a path they will never take. **Never write the literal prefix in prose**, tests and
documentation included, or the grep hands a reader a step that is not one.

## 7. Scope discipline

A comment-only change is a comment-only change: no bug fix, no rename, no restructuring in the same
commit. A reviewer skimming a comment sweep is not looking for logic, which is exactly where a real
change hides. Where a comment reveals a real problem, that is an issue, not a longer comment, and a
comment is never enforcement: prefer the machine-checkable form, and run `bin/comment_audit.sh` (§8)
over whatever you touched.

## 8. Auditing

`.claude/bin/comment_audit.sh <file>` is the mechanical pass: it catches the recurring shapes faster
than a reader can, and every hit is something a rule above already forbids. Its own block collects
this project's patterns. These are the generic three it starts from, worth running over a directory:

```bash
# Comments that narrate the following line, roughly.
git grep -nE '//[[:space:]]*(increment|decrement|return|set|get|loop over|iterate)' -- <src>

# Counts that rot.
git grep -nE '\b(two|three|four|five|six|all [a-z]+) (of the|supported|possible|cases|callers)\b' -- <src>

# Pointers to documents a downstream reader cannot open.
git grep -nE '(see|per|cf\.?) [A-Za-z_/]+\.(md|docx|xlsx)' -- <src>
```

## 9. Test comments

Everything above applies unchanged inside a test. Three shapes only bite here, and all three are §1
applied rather than exceptions to it:

- **A test's name is the first place its explanation belongs.** A comment saying what the test
  checks, above a test whose name already says it, is §4's narration. Where the two disagree the
  name is what a failing run prints, so fix the name. The comment that survives says *why this
  case*, not *what this asserts*.
- **The failure a test prevents is load-bearing; the mechanism it uses is not.** Keep the line
  naming what would silently go wrong. Cut the walk through the setup and the assertion below it: a
  reader who breaks the code already sees the assertion, and cannot see what it was protecting.
- **A regression test names the behaviour, never the ticket.** "the edge list used to be applied in
  order" stays; a bare issue number does not, and §4's ban on unopenable references is not softened
  by the reader being a contributor. State what went wrong, so the test survives the tracker.

Two things carry over that a test sweep will be tempted to drop. **Fixture builders are ordinary
functions** and their preconditions are ordinary preconditions. And **§6's marker prefix binds test
comments too**: a test that repeats one in prose puts a non-marker into the chain the grep produces.

<!-- FILL IN: delete this block once you have answered it.

Doc-comment form:  e.g. `///` and `//!`, docstrings, JSDoc, KDoc. Which form is used for what, and
  whether generated docs are published anywhere; a doc comment is read by people who will never
  open this file, so it has a different audience from an inline one.

Spelling and voice:  e.g. Canadian spelling in prose, imperative mood, no first person.

What this project bans outright:  the shapes that keep coming back in review here.

Where the design rationale lives, and whether source may cite it:  if that document is outside the
  shipped tree, the answer is no; see §4.
-->
