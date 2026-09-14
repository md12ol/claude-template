#!/usr/bin/env bash
# Exercise the template against a REAL project: a real code repository with a real working-docs
# repository's work/ history overlaid by this template's machinery, the way a project that adopted
# the template would look. test.sh proves the machinery on synthetic fixtures; this proves it on a
# working-docs tree with months of archives, a 150-item collab.md, parked tasks and two owners.
#
#     ./test_fixture.sh            run everything
#     ./test_fixture.sh -v         also print each check that passes
#
# Configure through the environment. The defaults are the project this template was extracted from;
# point them anywhere a code repo and a working-docs repo (with work/<owner>/ directories) exist.
#
#     FIXTURE_CODE       path to the code repository            (default /home/user/GraphEvolutionTool)
#     FIXTURE_CODE_REV   commit to check out as the code tree   (default: origin's default branch, one behind)
#     FIXTURE_DOCS       path to the working-docs repository    (default /home/user/GET-claude)
#     FIXTURE_DOCS_REV   commit whose work/ becomes the fixture (default 661feb9: a live task, a parked one,
#                                                                and every persistent doc the template seeds)
#     FIXTURE_OWNERS     "email=dir=Name;email=dir=Name"        (default: the two owners of that project)
#     FIXTURE_ME         the email this session runs as         (default: the first owner)
#
# Skipped, exit 0, when either repository is absent - CI for the template has neither.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || { echo "cannot enter the repo root" >&2; exit 1; }
ROOT="$PWD"
[[ "${1:-}" == "-v" ]] && export VERBOSE=1
. "$ROOT/test_lib.sh"

CODE_SRC="${FIXTURE_CODE:-/home/user/GraphEvolutionTool}"
DOCS_SRC="${FIXTURE_DOCS:-/home/user/GET-claude}"
DOCS_REV="${FIXTURE_DOCS_REV:-661feb9}"
CODE_REV="${FIXTURE_CODE_REV:-}"
OWNERS="${FIXTURE_OWNERS:-michael.dube@ovgu.de=mdube=Michael Dubé;35709889+md12ol@users.noreply.github.com=mdube=Michael Dubé;shorinbonsai@gmail.com=jsargant=James Sargant}"
ME="${FIXTURE_ME:-${OWNERS%%=*}}"
ME_DIR="$(tr ';' '\n' <<<"$OWNERS" | awk -F= -v e="$ME" '$1==e{print $2; exit}')"

for r in "$CODE_SRC" "$DOCS_SRC"; do
    [[ -d "$r/.git" ]] || { echo "test_fixture: $r is not a git repository - skipped"; exit 0; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- build the bed ---------------------------------------------------------------------------------
# project/            the code repo, one commit behind its own origin (so pull_main has work to do)
# project/.claude/    the template's working tree + the docs repo's work/ and reference/, configured
#                     as /setup would configure it, cloned from a bare origin it can push to
section "0. build the bed"
CODE_ORIGIN="$TMP/code_origin"; DOCS_ORIGIN="$TMP/docs_origin"
PROJ="$TMP/project"; DOCS="$PROJ/.claude"

git clone -q --bare "$CODE_SRC" "$CODE_ORIGIN" 2>/dev/null || { bad "clone the code repo"; summary; exit 1; }
git clone -q "$CODE_ORIGIN" "$PROJ" 2>/dev/null
git -C "$PROJ" config user.email "$ME"; git -C "$PROJ" config user.name "Fixture"
[[ -n "$CODE_REV" ]] || CODE_REV="HEAD~1"
git -C "$PROJ" reset -q --hard "$CODE_REV" || bad "check out the code rev $CODE_REV"

build="$TMP/docs_build"; mkdir -p "$build"
tar -C "$ROOT" --exclude=.git --exclude='test*.sh' --exclude=TEMPLATE.md --exclude=.github \
    --exclude=.gitlab-ci.yml -cf - . | tar -C "$build" -xf -
docs_src="$TMP/docs_src"
git clone -q "$DOCS_SRC" "$docs_src" 2>/dev/null && git -C "$docs_src" checkout -q "$DOCS_REV" \
    || { bad "check out the docs rev $DOCS_REV"; summary; exit 1; }
cp -r "$docs_src/work/." "$build/work/"
[[ -d "$docs_src/reference" ]] && cp -r "$docs_src/reference/." "$build/reference/"
rm -rf "$build/work/current" "$build/work/parked"

tracker=none; command -v gh >/dev/null && tracker=gh
cat > "$build/project.conf" <<EOF
PROJECT_NAME="$(basename "$CODE_SRC")"
DOCS_REPO_NAME="fixture-claude"
DOCS_REPO_URL="$DOCS_ORIGIN"
DOCS_BRANCH="main"
HOST="other"
TRACKER_CLI="$tracker"
TRACKER_REPO=""
PEOPLE="shared"
MACHINES="multi"
EOF
tr ';' '\n' <<<"$OWNERS" | awk -F= 'NF==3 {print $1 "\t" $2 "\t" $3}' > "$build/work/owners.txt"
cp "$build/gitattributes.multi-writer" "$build/.gitattributes"
# What /setup leaves behind: no FILL IN blocks, and the project's name in the title.
python3 - "$build/CLAUDE.md" "$(basename "$CODE_SRC")" <<'PY'
import re, sys
p, name = sys.argv[1], sys.argv[2]
t = re.sub(r'<!--.*?-->', '', open(p).read(), flags=re.S).replace('<PROJECT>', name)
open(p, 'w').write(t)
PY
git -C "$build" init -q -b main .
git -C "$build" config user.email "$ME"; git -C "$build" config user.name "Fixture"
git -C "$build" add -A && git -C "$build" commit -qm "fixture: template machinery over real working docs"
git clone -q --bare "$build" "$DOCS_ORIGIN"
git clone -q "$DOCS_ORIGIN" "$DOCS" 2>/dev/null
git -C "$DOCS" config user.email "$ME"; git -C "$DOCS" config user.name "Fixture"
# After the clone: `.claude/` with a trailing slash only matches a directory that exists.
git -C "$PROJ" check-ignore -q .claude || printf '\n.claude/\n' >> "$PROJ/.gitignore"

[[ -f "$DOCS/work/$ME_DIR/current/plan.md" ]] && ok "the bed has a live task for $ME_DIR" \
    || bad "the bed has a live task for $ME_DIR"
is "the code repo ignores .claude/" "$(cd "$PROJ" && git status --porcelain | grep -c '\.claude' || true)" "0"
n_arch="$(find "$DOCS/work/archive" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
[[ "$n_arch" -gt 10 ]] && ok "real archive present ($n_arch tasks)" || bad "real archive present" "$n_arch"
left="$(grep -c 'FILL IN' "$DOCS/CLAUDE.md" || true)"
is "CLAUDE.md is configured" "$left" "0"

brief() { (cd "$PROJ" && .claude/hooks/session_brief.sh 2>&1); }
lib()   { (cd "$PROJ" && . .claude/hooks/lib.sh && load_conf && resolve_owner && eval "echo \"$1\""); }

# --- 1. identity ------------------------------------------------------------------------------
section "1. lib.sh resolves the real owner table"
is "the session's owner resolves" "$(lib '$WORK_CURRENT')" "work/$ME_DIR/current"
is "the display name comes from the table" "$(lib '$OWNER_NAME')" \
   "$(tr ';' '\n' <<<"$OWNERS" | awk -F= -v e="$ME" '$1==e{print $3; exit}')"
others="$(cd "$PROJ" && . .claude/hooks/lib.sh && load_conf && resolve_owner && other_owners)"
hasnt "other_owners excludes me" "^$ME_DIR" "$others"
[[ -n "$others" ]] && ok "other_owners lists the other owner" || bad "other_owners lists the other owner"
is "a second address maps to the same directory" \
   "$(git -C "$PROJ" config user.email 35709889+md12ol@users.noreply.github.com; lib '$WORK_CURRENT')" "work/$ME_DIR/current"
git -C "$PROJ" config user.email "$ME"

# --- 2. session brief on real data --------------------------------------------------------------
section "2. session_brief on the real working docs"
start=$(date +%s%N); out="$(brief)"; ms=$(( ($(date +%s%N) - start) / 1000000 ))
hasnt "runs clean" "No such file" "$out"
hasnt "no shell error" "line [0-9]*:" "$out"
has "prints the handoff's first line" "^# Next session" "$out"
has "shows the Machine: stamp on a multi install" "Machine:" "$out"
has "extracts Start here" "Start here" "$out"
has "the counts line renders" "open \[ \]: [0-9]*   unverified \[~\]: [0-9]*   unfiled issues: [0-9]*   traps: [0-9]*" "$out"
stray="$(grep -cE '^[0-9]+([[:space:]]|$)' <<<"$out")"
is "no stray count line" "$stray" "0"
[[ "$ms" -lt 3000 ]] && ok "brief finishes in under 3s (${ms}ms)" || bad "brief is slow" "${ms}ms"

# The other owner's identity sees their own (empty) desk, not mine.
git -C "$PROJ" config user.email shorinbonsai@gmail.com
out="$(brief)"
has "the other owner is told they have no active task" "No active task" "$out"
has "and sees my work in flight" "Michael Dubé: 1 current" "$out"
git -C "$PROJ" config user.email nobody@nowhere.io
out="$(brief)"
has "an unknown address is stopped" "Unrecognised git user.email" "$out"
git -C "$PROJ" config user.email "$ME"

# --- 3. park and unpark the real task -----------------------------------------------------------
section "3. park and unpark the real live task"
WC="$DOCS/work/$ME_DIR/current"; WP="$DOCS/work/$ME_DIR/parked"
mkdir -p "$WP"; mv "$WC" "$WP/real-task"; mkdir -p "$WC"
printf '**Blocked on:** the fixture unparking it\n' >> "$WP/real-task/handoff.md"
out="$(brief)"
has "the brief lists the parked task" "parked: real-task" "$out"
has "with its blocker" "the fixture unparking it" "$out"
has "and reports no active task" "No active task" "$out"
rmdir "$WC" 2>/dev/null; mv "$WP/real-task" "$WC"
[[ -f "$WC/plan.md" ]] && ok "unpark restores the task at the top level" || bad "unpark nested the task"
out="$(brief)"
hasnt "no longer parked" "parked: real-task" "$out"
has "the task is live again" "Start here" "$out"

# --- 4. the docs repo round-trips through its origin ----------------------------------------------
section "4. commit and push the task directory; pull_main fast-forwards both repos"
(cd "$DOCS" && git add "work/$ME_DIR" && git commit -qm "save: fixture" && git push -q origin main 2>/dev/null) \
    && ok "the task directory pushes" || bad "the task directory pushes"
other="$TMP/other_clone"; git clone -q "$DOCS_ORIGIN" "$other"
git -C "$other" config user.email "$ME"; git -C "$other" config user.name Fixture
echo "- remote edit" >> "$other/work/traps.md"; git -C "$other" commit -qam "from the other machine"; git -C "$other" push -q origin main 2>/dev/null
out="$(cd "$PROJ" && .claude/hooks/pull_main.sh 2>&1)"
has "the docs clone fast-forwards" ".claude fast-forwarded" "$out"
has "the code repo fast-forwards on its default branch" "fast-forwarded to" "$out"
is "the code tree is now at origin" "$(git -C "$PROJ" rev-parse HEAD)" "$(git -C "$CODE_ORIGIN" rev-parse HEAD)"

# --- 5. the read-only gate --------------------------------------------------------------------------
section "5. cloud_ready"
out="$(cd "$PROJ" && .claude/checks/cloud_ready.sh 2>&1)"; rc=$?
is "cloud_ready exits 0 on the bed" "$rc" "0"
has "identity line names the owner" "PASS  git identity" "$out"
has "reports the docs clone" "PASS  working docs" "$out"

# --- 6. the command hook against this project's own commands ----------------------------------------
section "6. block_env_commands on the project's commands"
tier() {
    local out rc
    out="$(printf '{"tool_input":{"command":"%s"}}' "$1" | "$DOCS/hooks/block_env_commands.sh" 2>&1)"; rc=$?
    [[ $rc -eq 2 ]] && { echo block; return; }
    grep -q NOTICE <<<"$out" && echo warn || echo allow
}
is "cargo publish blocks"      "$(tier 'cargo publish')"                    block
is "cargo test allows"         "$(tier 'cargo test --workspace')"           allow
is "gh pr create warns"        "$(tier 'gh pr create --title x')"           warn
is "gh issue view allows"      "$(tier 'gh issue view 12 --json body')"     allow
is "git push -u warns"         "$(tier 'git push -u origin mdube_x')"       warn

# --- 7. union-merge audits on the real append-only docs ---------------------------------------------
section "7. union-merge audits on real data"
for f in decisions collab; do
    dup="$(grep -vE '^[[:space:]]*$' "$DOCS/work/$f.md" | sort | uniq -d | wc -l | tr -d ' ')"
    is "$f.md has no colliding lines" "$dup" "0"
done
n="$(grep -c '^### [0-9]' "$DOCS/work/collab.md")"
[[ "$n" -gt 5 ]] && ok "collab.md headings all at column 0 ($n items)" || bad "collab.md structure" "$n"

# --- 8. the rest of the machinery runs clean on the bed -------------------------------------------------
section "8. backup, hotfix warning, codex bridge"
out="$(cd "$PROJ" && env CLAUDE_DOCS_BACKUP_DIR="$TMP/bk" .claude/hooks/backup_docs.sh --force 2>&1)"
has "backup copies the docs" "backed up" "$out"
[[ -d "$TMP/bk/$(date +%F)/work/archive" ]] && ok "the archive is in the snapshot" || bad "the archive is in the snapshot"
out="$(echo '{"tool_input":{"file_path":".claude/hooks/session_brief.sh"}}' | "$DOCS/hooks/show_hotfixes.sh" 2>&1)"
has "editing a hook warns" "runs on everyone else" "$out"
(cd "$PROJ" && .claude/codex/install.sh >/dev/null 2>&1) && ok "codex bridge installs on the bed" || bad "codex bridge installs on the bed"
is "the bridge leaves the code repo clean" "$(cd "$PROJ" && git status --porcelain | grep -v "^?? \.claude" | tr "\n" " ")" ""

summary
