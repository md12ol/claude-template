# Hotfixes: temporary code in the tree

Every band-aid, stub, sleep, hardcoded value and workaround currently in the working tree; each
needs an exit condition or it lives forever. Maintained by `/save`, and `/done` stamps
`Last checked:`, so an old or missing stamp means nobody has assessed it lately. ⚠️ in a
`Remove when:` marks a **load-bearing** hotfix that breaks something today if removed. Group entries
under `## <theme>` headings by what unblocks them, the axis on which they get removed in batches.
**Where several people share the repo**, an *uncommitted* hotfix exists on one machine only, so read
`Owner:` and `Machine:` before assuming it is in your tree, and raise someone else's entry in
`collab.md` rather than deleting it. *(Drop those two fields if you work alone.)* **`/setup`
removes this file when `TRACKER_FIRST=yes`**, where the marker at the site and the issue that closes
it replace the entry.

---

## <theme: e.g. blocked on upstream, blocked on someone's work, ours to fix>

### <what was hacked>
- **Owner:** who put it there and who removes it.
- **Machine:** `owner's working tree, uncommitted` · `committed, in every tree` · `branch <name>`.
  This is what tells everyone else whether to expect the code locally.
- **Where:** `path` or symbol name; prefer function names over line numbers, they survive edits.
- **What it does:** the mechanism, if not obvious from the title. Optional.
- **Why it's a hotfix:** the problem it papers over, and why the proper fix wasn't done here.
- **Real fix:** what would make this unnecessary, and **who owns it** if it's someone else.
- **Remove when:** the concrete condition that makes it unnecessary.
- **Added:** <YYYY-MM-DD> - <short-slug of this hotfix, so the line is unique>
- **Last checked:** <YYYY-MM-DD>
