# Issue style: what a filed issue says

This file is about the words. *How* one gets filed (which tracker, what to confirm, which labels)
is `CLAUDE.md`'s filing block; the paste-ready skeleton is `templates/issue_bug.md`. **The test:**
could someone who has never seen this problem pick it up, reproduce it, and know when they are
finished, without asking a question first?

```markdown
**Problem** (3 lines max)
What is broken and what it costs. No history, no diagnosis.

**Solution** (2 lines max)
What to do, or `Unknown: needs <who or what owns the answer>`.

**Reproduce**
One command, and what you see. Above the fold.

**Environment**
Toolchain, branch, OS: whatever a "works for me" reply would turn on.

## Tasks            <- only when there is more than one step
- [ ] ...

**Done when:** the observable that settles it.

<details><summary>Details</summary>
Evidence, `path:line`, commit ids, measurements, what was ruled out.
</details>
```

## Rules

1. **Title is `component: symptom`**, the only part most people read. Not a sentence, not the fix.
2. **Never guess the solution.** Write `Unknown: needs <name>`: **naming who decides is the
   actionable content**, and a guess costs the reader an argument before any work starts.
3. **The reproducer stays visible**, one line, above any fold: a `<details>` block that swallows
   it makes a well-researched issue look thin.
4. **The environment block is mandatory on a defect.** "Works for me" is the commonest dead end.
5. **`Done when:` is not optional.** Tasks say what the work is; this settles when it is over.
6. **One issue, one decision.** A checklist owned by two people is two issues with a link.
7. **Link, don't paste.** `path:line` and commit ids survive refactors; paste only the error text.
8. **Labels come from `project.conf`:** exactly one of `KIND_LABELS`, none when that key is empty,
   none a workflow derives when `LABELS_DERIVED` is `yes`, and never an invented name, which most
   trackers create silently on first use. No severity or priority field: that is triage, and it
   belongs to whoever picks the issue up.
