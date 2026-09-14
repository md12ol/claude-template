#!/usr/bin/env bash
# Turn a PEOPLE="solo" working-docs repo into a PEOPLE="shared" one: restore what the solo setup
# removed, write the owner table, move live tasks under their owner, install the merge driver.
# /add-person runs it, then restores CLAUDE.md's deleted sections by hand and commits.
#
#     .claude/bin/add_person.sh <email> <dir> "<name>" [<email> <dir> "<name>"]…
#
# EVERYONE goes on the command line, the existing owner included: the table was deleted when there
# was only one person, so it has nobody in it. Three addresses for one person are three triples
# with the same <dir>. Never guess an address. Commits nothing.
#
# Test:  .claude/bin/add_person.sh   # refuses, and prints the usage

set -uo pipefail

# shellcheck source=../hooks/lib.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/lib.sh"
claude_paths; load_conf
cd "$CLAUDE_DIR" || die "add_person: cannot enter $CLAUDE_DIR"

# 1. Refuse anywhere the result would be ambiguous or hard to read afterwards.
is_shared && die "add_person: PEOPLE is already shared — a third person is one line in work/owners.txt"
[[ -n "$(git status --porcelain 2>/dev/null)" ]] && die "add_person: the .claude/ tree is dirty — this moves and restores files; commit or stash first"
[[ $# -ge 6 && $(( $# % 3 )) -eq 0 ]] || die "add_person: needs <email> <dir> \"<name>\" per person, at least two people"

me_email="$(git -C "$PROJECT_DIR" config user.email 2>/dev/null || true)"
me=""
for ((i = 1; i <= $#; i += 3)); do
    [[ "${!i}" == "$me_email" ]] && { j=$((i + 1)); me="${!j}"; }
done
[[ -n "$me" ]] || die "add_person: this session's git user.email '${me_email:-unset}' is not among the triples — one of them must be yours"

# 2. Restore from the solo removal's own commit, found by content rather than a remembered SHA.
sha="$(git log --diff-filter=D --format=%H -1 -- work/collab.md 2>/dev/null)"
[[ -n "$sha" ]] || die "add_person: no commit deleted work/collab.md — take the files from the template this repo came from, never a remembered copy"
git checkout "$sha^" -- work/collab.md work/collab_settled.md work/owners.txt \
                        gitattributes.multi-writer skills-optional \
    || die "add_person: the restore from $sha^ failed — resolve by hand"
mkdir -p work/meetings
echo "restored from ${sha:0:7}^: collab.md, collab_settled.md, owners.txt, gitattributes.multi-writer, skills-optional, meetings/"

# 3. The owner table, rewritten whole — it came back from the commit holding whoever was in it then.
{ printf '# The email-to-directory table. THE only copy: nothing else defines it.\n'
  printf '# Format: <git email><TAB><directory name><TAB><display name>.\n'
  printf '# One line per ADDRESS — work, personal and host noreply addresses are three lines\n'
  printf '# pointing at one directory. A missing address stops that person cold, deliberately.\n'
  for ((i = 1; i <= $#; i += 3)); do
      j=$((i + 1)); k=$((i + 2))
      printf '%s\t%s\t%s\n' "${!i}" "${!j}" "${!k}"
  done; } > work/owners.txt

# 4. Live tasks move under their owner. work/archive/ and work/meetings/ never do: a finished task
#    is the project's history and a meeting belongs to everyone.
mkdir -p "work/$me"
for d in current parked; do
    [[ -e "work/$d" ]] && { git mv "work/$d" "work/$me/$d" 2>/dev/null || mv "work/$d" "work/$me/$d"; }
done
echo "live tasks now at work/$me/current and work/$me/parked"

# 5. Flip the switch, install the driver, and verify it took — getting this wrong is silent.
sed -i 's/^PEOPLE=.*/PEOPLE="shared"/' project.conf || die "add_person: could not rewrite PEOPLE in project.conf"
cp gitattributes.multi-writer .gitattributes || die "add_person: gitattributes.multi-writer did not come back"
got="$(git check-attr merge -- work/decisions.md work/traps.md | sed 's/.*: //' | tr '\n' ' ')"
[[ "$got" == "union unspecified " ]] || die "add_person: the merge driver did not take (got: $got)"

# 6. The whole point, checked rather than assumed.
load_conf
resolve_owner
[[ "$WORK_CURRENT" == "work/$me/current" ]] || die "add_person: resolve_owner gives '$WORK_CURRENT', not work/$me/current — fix work/owners.txt, not your git identity"
echo "shared: $WORK_CURRENT resolves, merge driver verified"

# 7. CLAUDE.md's sections went in the same commit and cannot be restored wholesale — the file has
#    been edited since, and those edits are this project's. Name them for the skill to put back.
echo "restore these CLAUDE.md sections by hand from: git show ${sha}^:CLAUDE.md"
diff <(git show "$sha^:CLAUDE.md" 2>/dev/null | grep '^#') <(grep '^#' CLAUDE.md) \
    | sed -n 's/^< /  missing: /p' | head -6
exit 0
