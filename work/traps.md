# Traps: how this workspace actually behaves

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
- **Added:** <YYYY-MM-DD> - <short-slug of this trap, so the line is unique>

### The host's web merge button ignores `merge=union`, so a working-docs PR conflicts there
- **Bites when:** you click Merge on a pull request touching `work/*.md`. The host reports a
  conflict and offers its web editor, where you would hand-resolve an append-only log in a textarea.
  That is how one side's entries get dropped.
- **Do this instead:** merge locally, where `.gitattributes` is read.
  `git checkout main && git pull && git merge --no-ff origin/<branch> && git push origin main`,
  then read the tail with `git diff HEAD~1 -- work/`.
- **Why:** merge drivers are applied by *your* git, not by the host's servers. True even of `union`,
  which is built into git rather than custom.
- **Added:** 2026-09-14 - template-seeded · web-merge-ignores-union

### Auto-delete-on-merge does not fire on a pull request you merged locally
- **Bites when:** you finish a PR the way the rule above requires, `git merge --no-ff` then a push,
  and assume the repository setting cleaned the branch up. The host does show the PR as merged.
- **Do this instead:** delete both copies yourself as the last step, or let `/done` do it:
  `task.sh branch-done <branch>` checks the branch is merged first and never forces.
- **Why:** the setting acts on the *host's own merge action*. A local merge arrives as an ordinary
  push; the host flips the PR's state, but no merge action ran, so no cleanup ran either.
- **Added:** 2026-09-14 - template-seeded · auto-delete-misses-a-local-merge

### Two sessions in one checkout can silently apply your edits to the wrong branch
- **Bites when:** two agent sessions, or a session and a person, work in the same checkout at once
  on different branches. Nothing stops either from switching branches while the other has
  uncommitted edits, and an edit whose surrounding text matches on both branches then lands on the
  wrong tree. `git status` afterwards looks entirely normal.
- **Do this instead:** if a file reports being modified since you last read it, or
  `git branch --show-current` shows a branch you did not create, stop and read `git reflog`, whose
  timestamps make the interleaving obvious. Recover with `git stash push -- <files>`, switch back,
  `git stash apply`, and diff before trusting the result.
- **Why:** there is one checkout of the code and every branch shares it. The `.claude/` clone is a
  separate repository, so it protects the working docs from this and nothing else.
- **Added:** 2026-09-14 - template-seeded · two-sessions-one-checkout

### Concurrent agents overwrite each other's scratchpad files
- **Bites when:** several agents run at once and each writes a working file to the same scratch
  directory under an obvious name (`out.txt`, `patch.diff`). One agent's file is silently replaced
  with another's content mid-task, and the result is still a *valid* file.
- **Do this instead:** give every agent its own subdirectory, or a filename carrying its target.
  Then verify before applying: check the paths and line counts a patch claims are plausible.
- **Why:** nothing arbitrates the filename. A corrupt patch applies cleanly, so only inspection
  catches it.
- **Added:** 2026-09-14 - template-seeded · agents-overwrite-scratchpad-files
