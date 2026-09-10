# Retired traps — no longer bite, kept for the reasoning

Entries moved out of `traps.md` because the failure they describe has been fixed. They are kept
rather than deleted for one reason: **each names the fix that removed it**, so if that fix is ever
reverted the trap comes back exactly as written, and the next person to touch that code can find out
why it is the way it is.

Nothing here is a live hazard. A session reading `traps.md` does not need to read this file, and
`/load` and the session brief deliberately ignore it.

**Retire rather than delete when the mechanism could return** — a fix in code, a config someone
could revert, a dependency version. **Delete outright when the mechanism is simply gone** — the file
no longer exists, the tool was dropped, the platform changed under it. The test is "could this come
back", not "has anyone hit it lately".

---

### <the trap, stated as the mistake it prevented>

- **Bit when:** <the situation that triggered it.>
- **What happened:** <the symptom, as it actually appeared.>
- **Fixed by:** <the change that removed it, with a commit or a date. This is the part that matters.>

*Retired <YYYY-MM-DD> — <author> · <slug>.*
