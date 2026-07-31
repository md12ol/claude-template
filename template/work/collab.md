# Collaboration log — questions, answers, and overrides

<!-- DELETE THIS FILE IF YOU WORK ALONE. It only earns its place once a second person clones the
     repo and runs /start and /save on their own machine. -->

Shared by everyone who works in this repo. Everyone reads and writes it; it is not addressed at any
one person — a file called "to discuss with <name>" reads as self-referential on that person's
machine, which is the mistake this file exists to avoid.

## What goes here

- **A question** you want another owner to answer before you build on it.
- **A decision on your side that conflicts with or overrides theirs** — the kind where proceeding
  silently would waste someone's work.

Not every disagreement. If it needs no answer from anyone, it is a `decisions.md` entry instead.

## How to use it

**Raising.** Append a new item at the end of **Open**, numbered one higher than the last. Say what
you want — **Confirm**, **Decide**, or **FYI** — in the first line. An item with no ask sits open
forever. Link the reasoning rather than repeating it: `decisions.md`, `<YYYY-MM-DD>`.

**Answering.** Append your reply *inside* that item, beneath the existing text, as its own stamped
line. Do not edit what the other person wrote, and do not delete their words to make room for yours.

**Settling.** When an item is resolved, move the whole item to **Agreed** with the date, keeping
every stamp. Agreed items are never deleted — the trail is what stops the same argument recurring.

## Formatting rules — these are load-bearing, not style

If the repo root `.gitattributes` sets `merge=union` on `.claude/work/*.md` (recommended — see
`CLAUDE.md`, "More than one person uses this `.claude/`"), concurrent appends merge without conflict
markers. The cost: **union merge never conflicts**, and lines that are byte-identical on both sides
are folded together as shared context — silently interleaving two entries into one block that reads
as coherent and is not.

So, here and in every other `work/*.md`:

1. **An entry's first and last lines must be unique in the file.** Those are the boundary lines a
   merge treats as context. The heading carries the item number; the closing stamp repeats it.
2. **Close every item with its own number and a time:**
   `*#7 · raised <YYYY-MM-DD> <HH:MM> — <name>.*` — never a bare `*Raised <YYYY-MM-DD> — <name>.*`,
   which collides the moment one person raises two items in a day. The `HH:MM` is the second guard:
   two people appending minutes apart cannot produce the same stamp.
3. **Never close an entry with a bare `---`.** Headings delimit entries; a repeated horizontal rule
   is exactly the identical boundary line rule 1 warns about.
4. **No bare structural labels.** Write `- **Body:** <first sentence>`, not `- **Body:**` alone.

Audit before you push, and again after any merge:

```bash
grep -vE '^\s*$' .claude/work/collab.md | sort | uniq -d
```

Anything it prints is a line two entries could collapse onto.

Persistent: survives `/done`, because coordination outlives any one task.

---

## Open

### 1. <the ask, stated as what it changes for them>
**Confirm / Decide / FYI** — say which, in the first line.

What you did, what it overrides, and what you want back.

*#1 · raised <YYYY-MM-DD> <HH:MM> — <name>.*

> **Answer:** replies go here, inside the item, each with its own stamp.
> *#1 · answered <YYYY-MM-DD> <HH:MM> — <other name>.*

## Agreed

### <the item> — accepted (<YYYY-MM-DD>)
What was settled, and any consequence that outlived it — a doc now stale, a follow-up owed.
Agreed items are never deleted; the trail is what stops the same argument recurring.

*#<n> · settled <YYYY-MM-DD> <HH:MM> — <name>.*
