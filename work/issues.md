# Issues — work for other people

Staged for the tracker in two tiers, the difference being whether it has been root-caused.
Maintained by `/save`; `/done` lists anything still `Filed: not yet` before archiving. How issues
get filed — tool, confirmation rule, target project — lives in `CLAUDE.md`. Once filed, **the
tracker is the source of truth**: changes go there in the same session, and this file must not
become a private fork of it. **`/setup` removes this file when `TRACKER_FIRST=yes`**, where a
finding is reported in the session brief and filed as its own deliberate step.

---

## Parked — noticed, not investigated

### <what was noticed>
- **Where:** `path` or component, as far as it's known.
- **Impact:** why it matters — who or what it breaks.
- **Noticed:** <YYYY-MM-DD>, in <what you were doing when you hit it>

## Ready to file — root-caused and evidenced

### <title — imperative, issue-ready>
- **For:** teammate / team / unassigned
- **Project:** the tracker project it belongs to
- **Filed:** not yet
- **Component:** `path:line`
- **Body:** <open with a sentence on this line — a bare label is byte-identical in every entry>
  What's wrong, the mechanism with `path:line`, evidence, how to reproduce, candidate fixes.
