# Retired traps — no longer bite, kept for the reasoning

Entries moved out of `traps.md` once the failure they describe is fixed. Kept rather than deleted
for one reason: **each names the fix that removed it**, so reverting that fix brings the trap back
exactly as written, and the next person into that code can find out why it is the way it is.

Nothing here is a live hazard — `/load` and the session brief deliberately ignore it.

**Retire when the mechanism could return** (a fix in code, a revertable config, a dependency
version). **Delete when it is simply gone** (the file removed, the tool dropped, the platform
changed under it). The test is "could this come back", not "has anyone hit it lately".

Written by `/save` §7, which retires a trap whose cause that session removed.

---

### <the trap, stated as the mistake it prevented>

- **Bit when:** <the situation that triggered it.>
- **What happened:** <the symptom, as it actually appeared.>
- **Fixed by:** <the change that removed it, with a commit or a date. This is the part that matters.>

*Retired <YYYY-MM-DD> — <author> · <slug>.*
