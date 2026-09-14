# Comment style

**This binds every comment written or edited in this project.** It is short on purpose: the whole of
it reduces to one test and one habit, and everything else is that test applied to shapes that keep
recurring.

Where this file and a comment in the tree disagree, this file is the intent — fix the comment.

It is deliberately language-neutral. Fill in the FILL IN blocks with your project's own answers, and
delete any section that does not apply to how your language actually works.

---

## 1. The test

**Would deleting this make a competent reader — new to *this code*, not new to the field — more
likely to misunderstand or break it?**

No → delete it. That is the whole rule.

**The default is no comment.** One line is the norm; a second needs a reason a reader can act on.
Limits are ceilings, never targets.

Your reader knows the language, and knows what a hash map and a race condition are. They do not know
why *this* function takes the lock before reading the cache, or why *this* loop counts down. Write
the second thing, never the first.

## 2. Prefer removing the comment's reason to exist

The best outcome is not a tighter comment but code that no longer needs one. Prefer, in order:

**a clearer name · different structure · a validation or an assertion · a test · shipped
documentation · prose.**

A comment explaining what `d` holds is worse than renaming it; one warning that the caller must call
`init()` first is worse than a runtime check, or a type that makes it impossible; one describing the
three cases handled here is worse than three tests named after them.

Reach for prose only when none of the above can carry it — mostly for **why**, almost never for
**what**.

## 3. What earns a comment

- **A reason not visible from the code.** Why this algorithm and not the obvious one, why this
  constant, why the order of these two lines matters. The most valuable comment there is, and the
  one most often missing.
- **A precondition the type system cannot express** — one line, stating the failure, not the rule:
  "panics if the slice is empty" beats "the slice must not be empty".
- **A caller-visible effect that is easy to miss** — a parameter mutated in place, a global touched,
  a file left open.
- **A deliberate divergence from a sibling.** Where two similar functions differ on purpose, the odd
  one out says why — otherwise the next person "fixes" it.
- **A workaround for someone else's bug**, with enough detail to retire it: what breaks, and what
  would have to change for this to go away. Cross-reference it in `work/hotfixes.md`.

## 4. What to remove

- **Anything that narrates the next line.** `// increment the counter` above `counter += 1`.
- **Anything that restates a name.** If the comment is the name in a sentence, delete the comment.
- **Counts and roll-calls that rot.** "the three supported backends", "all five callers" — say "each
  backend", "every caller". A number is wrong the moment someone adds a sixth, and nothing tells you.
- **Commented-out code.** Version control already has it, with a date and an author.
- **A comment describing a state of the world** — "currently unused", "will be replaced next
  quarter". Say what the thing is *for*; that does not rot.
- **A pointer to a document the reader cannot open.** Shipped source citing an internal planning
  doc, a private tracker or a design file outside the repo is a dead end downstream. State the
  reason itself rather than where it was agreed.

## 5. Extension markers

When adding a feature means touching several places in a fixed order, mark each site with a literal,
greppable token rather than describing the sequence in prose somewhere else:

```
ADD A <THING> STEP <n>
```

so that one command finds every site at once:

```bash
git grep -nE "ADD AN? .* STEP [0-9]"
```

**The marker sits at the site that must change** — that is the point. A prose walkthrough lives away
from the code and drifts from it silently; a marker is found by whoever is already editing.

**Where a chain forks, the marker names the fork:** `ADD A BACKEND STEP 3 (for streaming)` beside
`ADD A BACKEND STEP 3 (for batch)`. Without it, a reader extending one path meets a numbered list
mixing their steps with a path they will never take, and nothing says which is which.

**Never write the literal prefix in prose**, including in tests and documentation, or the grep hands
a reader a step that is not one.

## 6. Scope discipline

A comment-only change is a comment-only change: no bug fix, no rename, no restructuring in the same
commit. A reviewer skimming a comment sweep is not looking for logic, which is exactly where a real
change hides.

## 7. Auditing

A mechanical pass catches the recurring shapes faster than a human can, and every hit is something a
rule above already forbids. Grow it as you find repeat offenders:

```bash
# Comments that narrate the following line, roughly.
git grep -nE '//[[:space:]]*(increment|decrement|return|set|get|loop over|iterate)' -- <src>

# Counts that rot.
git grep -nE '\b(two|three|four|five|six|all [a-z]+) (of the|supported|possible|cases|callers)\b' -- <src>

# Pointers to documents a downstream reader cannot open.
git grep -nE '(see|per|cf\.?) [A-Za-z_/]+\.(md|docx|xlsx)' -- <src>
```

<!-- FILL IN — delete this block once you have answered it.

Language and doc-comment form:  e.g. `///` and `//!`, docstrings, JSDoc, KDoc.
  Say which form is used for what, and whether generated docs are published anywhere. A doc comment
  has a different audience from an inline one: it is read by people who will never open this file.

Spelling and voice:  e.g. Canadian spelling in prose, imperative mood, no first person.

What this project bans outright:  the shapes that keep coming back in review here.

Where the project's design rationale lives, and whether source may cite it:  if the answer is a
  document outside the shipped tree, the answer to "may source cite it" is no — see §4.
-->
