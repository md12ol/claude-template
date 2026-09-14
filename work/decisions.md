# Decisions

Append-only, newest at the **bottom**. Never edit or delete a past entry: if a later session
reverses one, write a new entry that names and supersedes it, because the reversal trail is the
value. Log only what a cold reader could not re-derive from the code, and skip the obvious.
Maintained by `/save`; survives `/done`, since decisions constrain the codebase rather than a task.

---

## <YYYY-MM-DD> <HH:MM> — <author> — <short title>
**Chose:** what we're doing.
**Why:** the reasoning, in the terms it was actually argued.
**Rejected:** the alternatives considered, and what ruled them out.
**Affects:** `path:line`, or the area it constrains.
**Supersedes:** <date + title of the earlier decision>   (only if applicable)
