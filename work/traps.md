# Traps — how this workspace actually behaves

Permanent gotchas, distinct from `hotfixes.md`: a hotfix is *code you added and want to remove*, a
trap is *how this workspace behaves and always will*. The file exists because durable warnings kept
being parked in `handoff.md`, which `/save` overwrites every session, so they were deleted the
moment they stopped being top-of-mind. Read by `/load` and `/start`; entries leave only when they
stop being true, and move to `traps_retired.md` when a fix is what stopped them.

---

### <the trap, stated as the mistake it prevents>
- **Bites when:** the action that triggers it.
- **Do this instead:** the correct form.
- **Why:** the mechanism, one line.
- **Added:** <YYYY-MM-DD> — <short-slug of this trap, so the line is unique>
