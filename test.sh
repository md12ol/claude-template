#!/usr/bin/env bash
# Verify the template. Creates throwaway projects in a temp dir - each with this repository cloned
# in as .claude/, exactly as a real project has it - and exercises both team shapes, both machine
# settings, the hooks and the Codex bridge. Read-only with respect to this repository.
#
#     ./test.sh            run everything
#     ./test.sh -v         also print each check that passes
#
# Every case here corresponds to a defect that was actually found, or to a claim the README makes.
# When you fix a bug, add the case that would have caught it.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" || { echo "cannot enter the repo root" >&2; exit 1; }
ROOT="$PWD"
[[ "${1:-}" == "-v" ]] && export VERBOSE=1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Build a throwaway origin from the WORKING TREE, not from HEAD.
#
# `git clone "$ROOT"` would clone the last commit, so an uncommitted edit to a skill or a hook would
# be silently untested and the suite would pass on code nobody is running. Snapshot what is on disk
# instead, commit it into a scratch repo, and let every test project clone from that — which also
# gives each .claude/ a real origin to push to, the way a project's does.
ORIGIN="$TMP/origin"
mkdir -p "$ORIGIN"
tar -C "$ROOT" --exclude=.git -cf - . | tar -C "$ORIGIN" -xf -
git -C "$ORIGIN" init -q -b main .
git -C "$ORIGIN" config user.email test@example.com
git -C "$ORIGIN" config user.name Test
git -C "$ORIGIN" add -A
git -C "$ORIGIN" commit -qm "working tree under test"

# The machinery that actually ships as a project's working docs. Excludes .git/, this script, the
# CI files and TEMPLATE.md — those are the template's own scaffolding, which /setup offers to
# delete and which is allowed to talk about the template.
SHIPPED=(CLAUDE.md README.md project.conf comment_style.md settings.json root_CLAUDE.md.example
         gitattributes.multi-writer skills skills-optional hooks bin codex work reference
         output-styles)
scan() { grep -rniE "$1" "${SHIPPED[@]/#/$ROOT/}" 2>/dev/null || true; }

. "$ROOT/test_lib.sh"

# A project, with this repository cloned in as .claude/ the way a real one has it.
newproj() {  # newproj <name> [people] [machines] -> echoes the path
    local d="$TMP/$1"
    rm -rf "$d"; mkdir -p "$d"
    git -C "$d" init -q .
    git -C "$d" config user.email ada@example.com
    git -C "$d" config user.name "Ada Lovelace"
    git clone -q "$ORIGIN" "$d/.claude" 2>/dev/null
    git -C "$d/.claude" config user.email ada@example.com
    git -C "$d/.claude" config user.name "Ada Lovelace"
    printf 'PEOPLE="%s"\nMACHINES="%s"\n' "${2:-solo}" "${3:-single}" > "$d/.claude/project.conf"
    printf 'ada@example.com\tada\tAda Lovelace\ngrace@example.org\tgrace\tGrace Hopper\n' \
        > "$d/.claude/work/owners.txt"
    mkdir -p "$d/.claude/work/current" "$d/.claude/work/parked" \
             "$d/.claude/work/ada/current" "$d/.claude/work/ada/parked"
    # A configured install: /setup has run and resolved the FILL IN blocks. Almost every test below
    # is about a working install, not a fresh unconfigured clone — the one test that wants the
    # unconfigured case puts the marker back itself.
    sed -i 's/FILL IN/[filled in]/g' "$d/.claude/CLAUDE.md"
    echo "$d"
}

# ---------------------------------------------------------------------------------------------
section "1. every shell script parses"
while read -r f; do
    bash -n "$f" 2>/dev/null && ok "parse ${f#$ROOT/}" || bad "parse ${f#$ROOT/}"
done < <(find "$ROOT" -name '*.sh' -not -path '*/.git/*')

# ---------------------------------------------------------------------------------------------
section "2. nothing project-, host- or language-specific leaked in"
leak="$(scan 'GET-claude|md12ol|GraphEvolutionTool|shorinbonsai|uoguelph')"
is "no source-project identity ships" "${leak:-clean}" "clean"
lang="$(scan 'rustc|clippy|maturin|pyo3|__init__\.py')"
is "no language assumed" "${lang:-clean}" "clean"

# ---------------------------------------------------------------------------------------------
section "2b. an installed .claude/ is self-contained"
# The README promises a project's copy diverges freely and never reaches back here. Nothing
# installed may check for template updates, pin a template version, or fetch from it.
back="$(scan 'claude-template|fetch upstream|merge upstream')"
is "the shipped machinery never refers to the template repo" "${back:-clean}" "clean"
pin="$(scan 'TEMPLATE_VERSION|template_version|checks? for updates')"
is "no template version pin or update check" "${pin:-clean}" "clean"

# ---------------------------------------------------------------------------------------------
section "3. the repo root IS a .claude/ — clone it and it works"
d="$(newproj clone)"
for f in CLAUDE.md project.conf comment_style.md settings.json hooks/lib.sh work/owners.txt; do
    [[ -e "$d/.claude/$f" ]] && ok "clone provides $f" || bad "clone provides $f"
done
[[ -d "$d/.claude/reference" ]] && ok "reference/ is top-level" || bad "reference/ is top-level"
[[ -d "$d/.claude/work/reference" ]] && bad "reference/ must NOT be under work/" || ok "reference/ absent from work/"
[[ -e "$d/.claude/template" ]] && bad "no template/ subdirectory should remain" || ok "no template/ subdirectory"
[[ -e "$d/.claude/install.sh" ]] && bad "install.sh should be gone" || ok "no install.sh"
out="$(ls "$d/.claude/skills")"
hasnt "meeting skills are not active by default" "make-agenda" "$out"
[[ -d "$d/.claude/skills-optional/make-agenda" ]] && ok "meeting skills ship in skills-optional/" \
    || bad "meeting skills ship in skills-optional/"

# ---------------------------------------------------------------------------------------------
section "4. the project ignores .claude/, and the docs repo can push"
d="$(newproj ignore)"
(cd "$d" && .claude/bin/setup_apply.sh >/dev/null 2>&1)
(cd "$d" && git check-ignore -q .claude) && ok "the .gitignore line takes effect" || bad "the .gitignore line takes effect"
is "the project tracks nothing from .claude/" "$(cd "$d" && git status --porcelain | grep -c '\.claude' || true)" "0"
[[ -d "$d/.claude/.git" ]] && ok ".claude/ is its own repository" || bad ".claude/ is its own repository"
is "the docs repo has an origin" "$(git -C "$d/.claude" remote | head -1)" "origin"

# ---------------------------------------------------------------------------------------------
section "5. lib.sh resolves the four switch combinations"
for combo in "solo single work/current" "solo multi work/current" \
             "shared single work/ada/current" "shared multi work/ada/current"; do
    set -- $combo
    d="$(newproj "mx_$1_$2" "$1" "$2")"
    got="$(cd "$d" && . .claude/hooks/lib.sh && load_conf && resolve_owner && echo "$WORK_CURRENT")"
    is "$1/$2 resolves the task path" "$got" "$3"
done

d="$(newproj unknown shared multi)"
git -C "$d" config user.email nobody@nowhere.io
got="$(cd "$d" && . .claude/hooks/lib.sh && load_conf && resolve_owner && echo "[$WORK_CURRENT]")"
is "an unknown identity resolves to nothing, not a guess" "$got" "[]"

# Adding a person is a one-line edit in one file, and no other file defines the table.
defs="$(grep -rl 'ada@example.com' "$d/.claude" --exclude-dir=.git --exclude=test.sh 2>/dev/null \
        | grep -v owners.txt || true)"
is "owners.txt is the only copy of the table" "${defs:-single}" "single"

# ---------------------------------------------------------------------------------------------
section "6. session_brief"
d="$(newproj brief solo single)"

# A fresh clone, before /setup: the brief must send you to /setup, not /start. /start would write a
# plan against rules nobody has agreed yet.
sed -i 's/\[filled in\]/FILL IN/g' "$d/.claude/CLAUDE.md"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
has "an unconfigured install points at /setup" "Run /setup first" "$out"
hasnt "and does not point at /start" "start one with /start" "$out"

# Everything below is a configured install again.
sed -i 's/FILL IN/[filled in]/g' "$d/.claude/CLAUDE.md"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
has "reports no active task" "No active task" "$out"

mkdir -p "$d/.claude/work/current"
printf '# Plan\n- [x] done\n' > "$d/.claude/work/current/plan.md"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
# The zero-count bug: `grep -c … || echo 0` appended a second zero and broke the line in three.
# The bug produced "open [ ]: 0 / 0   unverified [~]: 0 / 0", so the tell is a line that is a
# bare number. Counting lines containing the marker does NOT catch it — only one line still has it.
stray="$(grep -cE '^[0-9]+([[:space:]]|$)' <<<"$out")"
is "no stray count line when a count is zero" "$stray" "0"
has "counts render" "open \[ \]: 0   unverified \[~\]: 0" "$out"

# Machine: stamp only on multi.
printf '# Next session\n**Machine:** host · saved 2026-01-01 · abc123\n\n## Start here\ngo\n' \
    > "$d/.claude/work/current/handoff.md"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
hasnt "Machine: stamp hidden on a single-machine install" "Machine:" "$out"
sed -i 's/MACHINES="single"/MACHINES="multi"/' "$d/.claude/project.conf"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
has "Machine: stamp shown on a multi-machine install" "Machine:" "$out"

# Incomplete .claude/ — the only missing-clone case a hook can catch.
mv "$d/.claude/skills" "$d/.claude/skills.bak"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
has "incomplete .claude/ is reported" "incomplete" "$out"
mv "$d/.claude/skills.bak" "$d/.claude/skills"

# ---------------------------------------------------------------------------------------------
section "7. block_env_commands — three tiers"
d="$(newproj block)"
tier() {  # tier <command> -> allow | warn | block
    local out rc
    out="$(printf '{"tool_input":{"command":"%s"}}' "$1" | "$d/.claude/hooks/block_env_commands.sh" 2>&1)"; rc=$?
    [[ $rc -eq 2 ]] && { echo block; return; }
    grep -q NOTICE <<<"$out" && echo warn || echo allow
}
is "git push warns"                  "$(tier 'git push')"                  warn
is "git push --force blocks"         "$(tier 'git push --force')"          block
is "git push -f blocks"              "$(tier 'git push -f')"               block
is "git push --dry-run allows"       "$(tier 'git push --dry-run')"        allow
is "npm publish blocks"              "$(tier 'npm publish')"               block
is "npm publish --dry-run allows"    "$(tier 'npm publish --dry-run')"     allow
is "cargo publish --dry-run allows"  "$(tier 'cargo publish --dry-run')"   allow
is "kubectl apply blocks"            "$(tier 'kubectl apply -f x.yaml')"   block
is "make deploy blocks"              "$(tier 'make deploy')"               block
is "make test allows"                "$(tier 'make test')"                 allow
is "npm view allows"                 "$(tier 'npm view react')"            allow
is "echo pushing allows"             "$(tier 'echo pushing to prod')"      allow

# The greedy-capture bug: a sibling "description" key that merely MENTIONS --force used to be
# swept into the captured command, so a plain push blocked. The parser must read the command key
# and nothing else.
pair() {  # pair <command> <description> -> allow | warn | block
    local out rc
    out="$(printf '{"tool_input":{"command":"%s","description":"%s"}}' "$1" "$2" \
           | "$d/.claude/hooks/block_env_commands.sh" 2>&1)"; rc=$?
    [[ $rc -eq 2 ]] && { echo block; return; }
    grep -q NOTICE <<<"$out" && echo warn || echo allow
}
is "a description mentioning --force does not block a push" \
   "$(pair 'git push' 'push the branch, not --force')" warn
is "a description mentioning publish does not block a test" \
   "$(pair 'npm test' 'checks before we npm publish')"  allow
is "the command still decides on its own" \
   "$(pair 'git push --force' 'routine')"               block

# ---------------------------------------------------------------------------------------------
section "8. park and unpark round trip"
d="$(newproj park shared multi)"
eval "$(cd "$d" && . .claude/hooks/lib.sh && load_conf && resolve_owner && echo "WC=$WORK_CURRENT; WP=$WORK_PARKED")"
cd "$d/.claude" || { bad "cannot enter the park fixture"; return 1 2>/dev/null || exit 1; }
mkdir -p "$WC"
printf '# Plan\n- [ ] a\n' > "$WC/plan.md"
printf '# Next session\n**Blocked on:** PR #482 merging\n' > "$WC/handoff.md"
(cd "$d" && .claude/bin/task.sh park api-rename >/dev/null) && ok "task.sh park exits 0" || bad "task.sh park exits 0"
is "park empties the live directory" "$(ls -A "$WC" | wc -l | tr -d ' ')" "0"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
has "the brief lists the parked task" "parked: api-rename" "$out"
has "the brief shows its blocker" "PR #482 merging" "$out"
out="$(cd "$d" && .claude/bin/task.sh unpark api-rename 2>&1)"
has "unpark reports the blocker it was parked on" "PR #482 merging" "$out"
[[ -f "$WC/plan.md" ]] && ok "unpark restores plan.md at the top level" || bad "unpark nested the task"
is "nothing left parked" "$(ls -A "$WP" | wc -l | tr -d ' ')" "0"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
hasnt "the brief no longer lists it as parked" "parked: api-rename" "$out"
cd "$ROOT" || exit 1

# ---------------------------------------------------------------------------------------------
section "9. pull_main only ever fast-forwards"
up="$TMP/up"; mkdir -p "$up"; git -C "$up" init -q -b main .
git -C "$up" config user.email a@b.c; git -C "$up" config user.name A
echo one > "$up/f"; git -C "$up" add -A; git -C "$up" commit -qm one
w="$TMP/w"; git clone -q "$up" "$w"
git -C "$w" config user.email a@b.c; git -C "$w" config user.name A
git clone -q "$ORIGIN" "$w/.claude" 2>/dev/null
echo two >> "$up/f"; git -C "$up" commit -qam two
out="$(cd "$w" && .claude/hooks/pull_main.sh 2>&1)"
has "fast-forwards when clean and behind" "fast-forwarded" "$out"
echo three >> "$up/f"; git -C "$up" commit -qam three
echo "LOCAL EDIT" > "$w/f"
out="$(cd "$w" && .claude/hooks/pull_main.sh 2>&1)"
has "declines on a dirty tree" "fast-forward failed" "$out"
is "and changes nothing" "$(cat "$w/f")" "LOCAL EDIT"
git -C "$w" checkout -q -- f
git -C "$w" checkout -qb feature
out="$(cd "$w" && .claude/hooks/pull_main.sh 2>&1)"
is "silent on a feature branch" "${out:-silent}" "silent"

# ---------------------------------------------------------------------------------------------
section "10. gitattributes narrows union merge to the append-only docs"
g="$TMP/ga"; mkdir -p "$g/work"; git -C "$g" init -q .
cp "$ROOT/gitattributes.multi-writer" "$g/.gitattributes"
touch "$g/work/decisions.md" "$g/work/traps.md" "$g/work/issues.md" "$g/work/hotfixes.md"
attr() { git -C "$g" check-attr merge -- "$1" | sed 's/.*: //'; }
is "decisions.md union-merges" "$(attr work/decisions.md)" "union"
is "traps.md does NOT union-merge" "$(attr work/traps.md)" "unspecified"
is "issues.md does NOT union-merge" "$(attr work/issues.md)" "unspecified"
is "hotfixes.md does NOT union-merge" "$(attr work/hotfixes.md)" "unspecified"

# ---------------------------------------------------------------------------------------------
section "11. seeded docs survive their own union-merge audit"
for f in "$ROOT"/work/*.md; do
    dup="$(grep -vE '^[[:space:]]*$' "$f" | sort | uniq -d)"
    is "no colliding lines in $(basename "$f")" "${dup:-clean}" "clean"
done

# ---------------------------------------------------------------------------------------------
section "12. codex bridge"
d="$(newproj codex)"
out="$(cd "$d" && .claude/codex/install.sh 2>&1)"
has "installs" "Codex bridge installed" "$out"
[[ -L "$d/AGENTS.md" ]] && ok "AGENTS.md is a link" || bad "AGENTS.md is a link"
has "entrypoints are excluded privately" "/AGENTS.md" "$(cat "$d/.git/info/exclude")"
is "nothing new is tracked" "$(cd "$d" && git status --porcelain | grep -cv '^?? .claude')" "0"
mkdir -p "$d/.claude/codex/skills/ghost"
printf -- '---\nname: ghost\ndescription: x\n---\n' > "$d/.claude/codex/skills/ghost/SKILL.md"
out="$(cd "$d" && .claude/codex/check_bridge.sh 2>&1 || true)"
has "detects an orphaned wrapper" "orphaned" "$out"
rm -rf "$d/.claude/codex/skills/ghost"
sed -i 's/^description: .*/description: CHANGED/' "$d/.claude/skills/park/SKILL.md"
out="$(cd "$d" && .claude/codex/check_bridge.sh 2>&1 || true)"
has "detects a stale wrapper description" "stale description" "$out"
(cd "$d" && .claude/codex/generate_wrappers.sh >/dev/null 2>&1)
(cd "$d" && .claude/codex/check_bridge.sh >/dev/null 2>&1) && ok "regenerating fixes it" || bad "regenerating fixes it"

# ---------------------------------------------------------------------------------------------
section "13. cloud pair"
d="$(newproj cloud)"
out="$(cd "$d" && env CLAUDE_CODE_REMOTE= .claude/bin/cloud_setup.sh 2>&1 || true)"
has "cloud_setup refuses off a container" "not a cloud session" "$out"
(cd "$d" && .claude/bin/cloud_ready.sh >/dev/null 2>&1) && ok "cloud_ready passes on a clean install" \
    || bad "cloud_ready passes on a clean install"
out="$(cd "$d" && .claude/bin/cloud_ready.sh 2>&1)"
hasnt "cloud_ready reports no failures" "^FAIL" "$out"

# ---------------------------------------------------------------------------------------------
section "14. every skill has usable frontmatter"
for f in "$ROOT"/skills/*/SKILL.md "$ROOT"/skills-optional/*/SKILL.md; do
    name="$(basename "$(dirname "$f")")"
    is "$name declares its name" "$(sed -n '2s/^name: //p' "$f")" "$name"
    d="$(sed -n '3s/^description: //p' "$f")"
    [[ ${#d} -gt 40 ]] && ok "$name has a real description" || bad "$name has a real description"
done

# ---------------------------------------------------------------------------------------------
section "15. settings.json is valid and wires only what needs no configuring"
if command -v python3 >/dev/null; then
    python3 -m json.tool "$ROOT/settings.json" >/dev/null 2>&1 \
        && ok "settings.json is valid JSON" || bad "settings.json is valid JSON"
    python3 -m json.tool "$ROOT/codex/hooks.json" >/dev/null 2>&1 \
        && ok "codex/hooks.json is valid JSON" || bad "codex/hooks.json is valid JSON"
fi
s="$(cat "$ROOT/settings.json")"
has "session_brief is wired by default" "session_brief" "$s"
hasnt "block_env is NOT wired by default" "block_env" "$s"

# ---------------------------------------------------------------------------------------------
section "15b. the solo removal leaves a working install"
# /setup deletes six things on PEOPLE=solo. The risk is not the deletion; it is something that
# quietly read one of them and now fails at session start, which is the worst place to find out.
d="$(newproj solo_strip solo single)"
# The removal is setup_apply.sh's, not a copy of it here: a re-implementation in the suite tests
# the suite. Its `git rm -f` matters — the fixture modified owners.txt after cloning, plain
# `git rm` refuses on a modified file, and the removals then silently do not happen.
out="$(cd "$d" && .claude/bin/setup_apply.sh 2>&1)"
has "setup_apply reports the solo removal" "solo: removed" "$out"
still="$(cd "$d/.claude" && ls -d work/collab.md work/collab_settled.md work/owners.txt \
         gitattributes.multi-writer skills-optional work/meetings 2>/dev/null || true)"
is "the removal actually removed everything" "${still:-gone}" "gone"
out="$(cd "$d" && .claude/hooks/session_brief.sh 2>&1)"
hasnt "session_brief does not error after the removal" "No such file" "$out"
has "session_brief still reports" "No active task" "$out"
(cd "$d" && .claude/bin/cloud_ready.sh >/dev/null 2>&1) && ok "cloud_ready still passes" || bad "cloud_ready still passes"
got="$(cd "$d" && . .claude/hooks/lib.sh && load_conf && resolve_owner && echo "$WORK_CURRENT")"
is "paths still resolve with no owners.txt" "$got" "work/current"
got="$(cd "$d" && .claude/bin/task.sh paths 2>&1)"
has "task.sh paths still works with no owners.txt" "WORK_CURRENT=work/current" "$got"
out="$(printf '{"tool_input":{"command":"git push --force"}}' | "$d/.claude/hooks/block_env_commands.sh" 2>&1; echo "rc=$?")"
has "the command hook still blocks" "rc=2" "$out"
(cd "$d" && .claude/codex/check_bridge.sh >/dev/null 2>&1) && ok "codex bridge still validates" || bad "codex bridge still validates"

# session_brief and cloud_setup DO name owners.txt, and that is correct — they read it only when
# PEOPLE=shared. What matters is that every executable still runs clean with the file absent, so
# assert behaviour rather than the absence of a mention: a script may refer to a file it tolerates.
# The scripts that take no arguments. task.sh, setup_apply.sh and add_person.sh do, and have their
# own sections below; running them bare here would test the usage message, not the removal.
for h in "$d"/.claude/hooks/*.sh "$d"/.claude/bin/cloud_*.sh; do
    n="$(basename "$h")"
    [[ "$n" == "lib.sh" ]] && continue
    o="$(cd "$d" && env CLAUDE_CODE_REMOTE= "$h" </dev/null 2>&1)"; rc=$?
    hasnt "$n runs clean without the removed files" "No such file or directory" "$o"
    # cloud_setup exits 3 off a container by design; everything else must succeed.
    if [[ "$n" == "cloud_setup.sh" ]]; then
        is "$n refuses off a container, as designed" "$rc" "3"
    else
        is "$n exits 0" "$rc" "0"
    fi
done

# ---------------------------------------------------------------------------------------------
section "15c. removing the Codex bridge leaves a working install"
d="$(newproj nocodex)"
(cd "$d/.claude" && git rm -qrf codex)
[[ -e "$d/.claude/codex" ]] && bad "codex/ removed" || ok "codex/ removed"
for h in "$d"/.claude/hooks/*.sh "$d"/.claude/bin/cloud_*.sh; do
    n="$(basename "$h")"; [[ "$n" == "lib.sh" ]] && continue
    o="$(cd "$d" && env CLAUDE_CODE_REMOTE= "$h" </dev/null 2>&1)"; rc=$?
    hasnt "$n runs clean with no codex/" "No such file or directory" "$o"
    [[ "$n" == "cloud_setup.sh" ]] || is "$n exits 0 with no codex/" "$rc" "0"
done

# ---------------------------------------------------------------------------------------------
section "15d. the root CLAUDE.md example is substitutable"
ex="$ROOT/root_CLAUDE.md.example"
has "carries a project placeholder" "<PROJECT>" "$(cat "$ex")"
has "carries a clone-URL placeholder" "<DOCS_REPO_URL>" "$(cat "$ex")"
# setup_apply.sh writes it. PROJECT_NAME defaults to the project directory's basename, so name the
# fixture directory after the project the file should end up describing.
d="$(newproj myproject solo single)"
printf 'PEOPLE="solo"\nMACHINES="single"\nDOCS_REPO_URL="git@example.com:me/myproject-claude.git"\n' \
    > "$d/.claude/project.conf"
(cd "$d" && .claude/bin/setup_apply.sh >/dev/null 2>&1)
outfile="$d/CLAUDE.md"
[[ -f "$outfile" ]] && ok "setup_apply writes the project's root CLAUDE.md" || bad "setup_apply writes the project's root CLAUDE.md"
# The explanation block is instructions to whoever runs /setup, not content for the project's file.
hasnt "the explanation block is stripped" "COPY THIS TO THE PROJECT" "$(cat "$outfile")"
hasnt "no HTML comment survives" "<!--" "$(cat "$outfile")"
has "the heading is the first content line" "^# myproject" "$(sed -n '1,3p' "$outfile")"
hasnt "no placeholder survives substitution" "<PROJECT>\|<DOCS_REPO_URL>" "$(cat "$outfile")"
has "the result names the project" "myproject" "$(cat "$outfile")"
has "the result carries the clone command" "git clone git@example.com" "$(cat "$outfile")"
# An existing root CLAUDE.md is the project's own file and is never overwritten.
printf '# theirs\n' > "$outfile"
out="$(cd "$d" && .claude/bin/setup_apply.sh 2>&1)"
is "an existing root CLAUDE.md is left alone" "$(cat "$outfile")" "# theirs"
has "and the pointer block is printed instead" "was NOT touched" "$out"

# ---------------------------------------------------------------------------------------------
section "16. every file says what it is, in its first few lines"
# A reader opening any file cold should learn its purpose without reading the whole thing. JSON is
# exempt: it has no comment syntax, and an unknown key risks a strict validator disabling the file.
while read -r f; do
    case "$f" in
        *.json) continue ;;
        codex/skills/*) continue ;;                       # generated; the generator is checked instead
        *.md)
            if head -1 "$ROOT/$f" | grep -q '^---$'; then
                # A skill: its frontmatter description IS the docstring.
                d="$(sed -n '3s/^description: //p' "$ROOT/$f")"
                [[ ${#d} -gt 40 ]] && ok "$f describes itself" || bad "$f describes itself"
            else
                body="$(sed -n '1,10p' "$ROOT/$f" | grep -vE '^#|^\s*$' | head -1)"
                [[ -n "$body" ]] && ok "$f describes itself" || bad "$f describes itself" "no prose in the first 10 lines"
            fi ;;
        *)
            hdr="$(sed -n '1,6p' "$ROOT/$f" | grep -E '^\s*(#|<!--)' | grep -vE '^#!' | head -1)"
            [[ -n "$hdr" ]] && ok "$f describes itself" || bad "$f describes itself" "no comment header" ;;
    esac
done < <(cd "$ROOT" && git ls-files)

# ---------------------------------------------------------------------------------------------
section "17. a configured install is not reported as unconfigured"
# The setup guard greps CLAUDE.md for its FILL IN blocks. CLAUDE.md used to discuss "FILL IN
# blocks" in LIVE PROSE as well, in the shared-install section — which /setup deletes on a solo
# install and keeps on a shared one. So a configured SHARED project reported "not configured yet"
# at every session start, forever, and /setup's own step-0 gate read it as unfinished. Invisible
# solo, which is why it survived. Strip the comment blocks the way /setup does, then assert.
for shape in solo shared; do
    d="$(newproj "configured_$shape" "$shape" single)"
    # Undo the fixture's blunt marker substitution, then remove the blocks properly.
    cp "$ORIGIN/CLAUDE.md" "$d/.claude/CLAUDE.md"
    python3 - "$d/.claude/CLAUDE.md" <<'STRIP'
import re, sys
p = sys.argv[1]
text = open(p).read()
open(p, 'w').write(re.sub(r'<!--.*?-->', '', text, flags=re.S))
STRIP
    left="$(grep -c 'FILL IN' "$d/.claude/CLAUDE.md" || true)"
    is "$shape: no marker survives in live prose" "$left" "0"
    out="$(cd "$d" && .claude/hooks/session_brief.sh 2>&1)"
    hasnt "$shape: the brief does not claim it is unconfigured" "has not been configured yet" "$out"
done

# ---------------------------------------------------------------------------------------------
section "18. bin/task.sh — paths, start, park, unpark, archive"
d="$(newproj task shared multi)"
t() { (cd "$d" && .claude/bin/task.sh "$@" 2>&1); }
trc() { (cd "$d" && .claude/bin/task.sh "$@" >/dev/null 2>&1); echo $?; }
eval "$(t paths)"
is "paths gives the owner's live directory" "$WORK_CURRENT" "work/ada/current"
is "paths gives the parked directory"       "$WORK_PARKED"  "work/ada/parked"
is "paths is eval-able and carries both switches" "$PEOPLE/$MACHINES" "shared/multi"
is "paths exits 0" "$(trc paths)" "0"
WC="$d/.claude/$WORK_CURRENT"; WP="$d/.claude/$WORK_PARKED"

# An unrecognised address stops every command. Never a guess: the wrong directory is silent.
git -C "$d" config user.email nobody@nowhere.io
is "an unknown owner exits 1" "$(trc paths)" "1"
has "and says which address, and where the table is" "nobody@nowhere.io" "$(t paths)"
has "naming work/owners.txt" "work/owners.txt" "$(t paths)"
git -C "$d" config user.email ada@example.com

# pull never blocks a session, whatever the docs clone's remote is doing.
is "pull exits 0 with an origin" "$(trc pull)" "0"
is "pull says nothing when there is nothing to say" "$(t pull)" ""
git -C "$d/.claude" remote set-url origin "$TMP/nowhere.git"
is "pull exits 0 with an unreachable origin" "$(trc pull)" "0"
has "and says so in one line" "pull it by hand" "$(t pull)"
git -C "$d/.claude" remote set-url origin "$ORIGIN"
before="$(cd "$d" && git status --porcelain; git -C "$d" rev-parse --abbrev-ref HEAD)"
t pull >/dev/null
is "pull leaves the code repo exactly as it was" "$(cd "$d" && git status --porcelain; git -C "$d" rev-parse --abbrev-ref HEAD)" "$before"

# start
rm -rf "$WC"
out="$(t start "rename the API")"
is "start prints the live path" "$out" "work/ada/current"
has "start seeds history.md with the objective" "^# History — rename the API" "$(cat "$WC/history.md")"
has "the seed says who maintains it" "Maintained by" "$(cat "$WC/history.md")"
[[ -f "$WC/handoff.md" ]] && bad "start must not write handoff.md" || ok "start does not write handoff.md"
is "start refuses a non-empty directory" "$(trc start "another thing")" "1"
has "and lists what is in the way" "history.md" "$(t start "another thing")"

# park / unpark
printf '# Plan\n' > "$WC/plan.md"
printf '# Next session\n**Blocked on:** PR #482 merging\n' > "$WC/handoff.md"
is "park refuses a slug with spaces" "$(trc park "api rename")" "1"
is "park refuses an uppercase slug"  "$(trc park "API")"        "1"
is "park exits 0" "$(trc park api-rename)" "0"
[[ -f "$WP/api-rename/plan.md" ]] && ok "park puts plan.md at the top of the parked dir" \
    || bad "park puts plan.md at the top of the parked dir"
is "park leaves the live directory empty" "$(ls -A "$WC" | wc -l | tr -d ' ')" "0"
is "park refuses a slug already parked" "$(trc park api-rename)" "1"
is "unpark refuses a slug that is not parked" "$(trc unpark no-such-task)" "1"
has "unpark prints the blocker" "PR #482 merging" "$(t unpark api-rename)"
[[ -f "$WC/plan.md" ]] && ok "unpark restores plan.md at the top level, not nested" \
    || bad "unpark nested the task one level down"
# The nesting guard: with a non-empty live directory the move would bury the task inside it.
printf 'x\n' > "$WC/stray.md"
mkdir -p "$WP/other"; printf '# Plan\n' > "$WP/other/plan.md"
is "unpark refuses while a task is live" "$(trc unpark other)" "1"
[[ -f "$WP/other/plan.md" ]] && ok "and leaves the parked task where it was" || bad "unpark moved it anyway"
rm -f "$WC/stray.md"; rm -rf "$WP/other"

# archive
rm -f "$WC/plan.md"
is "archive refuses with no plan.md" "$(trc archive api-rename)" "1"
printf '# Plan\n' > "$WC/plan.md"; printf 'h\n' > "$WC/handoff.md"; printf 's\n' > "$WC/plan_superseded.md"
out="$(t archive "API Rename")"
is "archive normalises the slug and dates the directory" "$out" "work/archive/$(date +%Y-%m)_api-rename"
is "archive leaves the live directory empty" "$(ls -A "$WC" | wc -l | tr -d ' ')" "0"
# plan_superseded.md is created lazily, so it is the one that gets left behind by hand.
[[ -f "$d/.claude/$out/plan_superseded.md" ]] && ok "archive takes plan_superseded.md too" \
    || bad "archive left plan_superseded.md behind"
printf '# Plan\n' > "$WC/plan.md"
is "archive refuses an existing archive directory" "$(trc archive "api-rename")" "1"
has "and suggests a suffix rather than overwriting" "api-rename-2" "$(t archive api-rename)"

# ---------------------------------------------------------------------------------------------
section "18b. bin/task.sh — stamp, check-stamp, audit, commit"
is "stamp prints nothing on a single-machine install" \
   "$( (cd "$(newproj stamp1 solo single)" && .claude/bin/task.sh stamp 2>&1) )" ""
# The stamp carries the CODE repo's HEAD, so the fixture project needs one.
git -C "$d" commit -q --allow-empty -m "first commit"
out="$(t stamp)"
has "stamp is the Machine: line on multi" "^\*\*Machine:\*\* .* · saved [0-9-]* [0-9:]* · " "$out"
has "stamp carries the code repo's HEAD" "$(git -C "$d" rev-parse --short HEAD)" "$out"
is "stamp is one line" "$(wc -l <<<"$out" | tr -d ' ')" "1"

# check-stamp: the question /load asks before trusting a handoff.
printf '# Next session\n' > "$WC/handoff.md"
out="$(t check-stamp)"
has "no stamp is reported, not treated as divergence" "no stamp" "$out"
is "and exits 0" "$(trc check-stamp)" "0"
{ printf '# Next session\n'; t stamp; } > "$WC/handoff.md"
is "a stamp this machine just wrote exits 0" "$(trc check-stamp)" "0"
has "and says so" "same machine" "$(t check-stamp)"
# Backticks and a missing time are both real: handoffs written before the format settled have them.
printf '# Next session\n**Machine:** `elsewhere` · saved 2026-09-11 · `f466d98`\n' > "$WC/handoff.md"
out="$(t check-stamp)"
is "a foreign SHA exits 1" "$(trc check-stamp)" "1"
has "naming the SHA it cannot find" "f466d98" "$out"
has "and refusing to merge or reset" "never merge or reset" "$out"
has "a stamp from another machine is reported as such" "written on elsewhere" "$out"
# A docs clone with commits origin lacks is the other half of the divergence.
{ printf '# Next session\n'; t stamp; } > "$WC/handoff.md"
(cd "$d/.claude" && git add -A && git commit -qm "local only")
out="$(t check-stamp)"
is "a docs clone ahead of origin exits 1" "$(trc check-stamp)" "1"
has "saying how far ahead" "origin lacks" "$out"

# audit
a="$d/.claude/work/audit_fixture.md"
printf '## 2026-01-01 10:00 — Ada — one\n- **Body:** a real sentence\n' > "$a"
is "a clean file exits 0" "$(trc audit work/audit_fixture.md)" "0"
printf '## 2026-01-01 10:00 — Ada — one\n- **Body:**\n## 2026-01-02 11:00 — Ada — two\n- **Body:**\n' > "$a"
is "a duplicated line exits 1" "$(trc audit work/audit_fixture.md)" "1"
has "and prints the line two entries could collapse onto" "Body" "$(t audit work/audit_fixture.md)"
# The splice union merge can make and `uniq -d` cannot see: a heading that is no longer at column 0.
printf '### 1. first item\nsome text ### 2. second item\n### 3. third item\n' > "$a"
is "a mid-line item heading exits 1" "$(trc audit work/audit_fixture.md)" "1"
has "and is named as a splice, not a duplicate" "mid-line" "$(t audit work/audit_fixture.md)"
rm -f "$a"
is "the default file list is the union-merged three" "$(trc audit)" "0"

# commit. The suite's shared ORIGIN has main checked out and refuses a push into it, so give this
# clone a bare origin — which is what a real docs repo has anyway.
BARE="$TMP/task_origin.git"
git clone -q --bare "$d/.claude" "$BARE"
git -C "$d/.claude" remote set-url origin "$BARE"
git -C "$d/.claude" fetch -q origin
printf 'saved\n' >> "$WC/plan.md"
out="$(t commit "save: task — a line")"
has "commit reports the SHA and the message" "save: task — a line" "$out"
has "commit pushes when there is an origin" "pushed" "$out"
is "the push actually landed" \
   "$(git -C "$d/.claude" rev-parse HEAD)" "$(git -C "$BARE" rev-parse main)"
has "a second commit with nothing staged says so" "nothing staged" "$(t commit "save: nothing")"
# A rejected push means the other machine saved first. Reported, never forced.
other="$TMP/task_other"; git clone -q "$BARE" "$other"
git -C "$other" config user.email ada@example.com; git -C "$other" config user.name Ada
git -C "$other" commit -q --allow-empty -m "from the other machine"
git -C "$other" push -q origin main
printf 'later\n' >> "$WC/plan.md"
out="$( (cd "$d" && .claude/bin/task.sh commit "save: rejected" 2>&1) )"; rc=$?
is "a rejected push exits 1" "$rc" "1"
has "says the other machine saved first" "the other machine saved first" "$out"
hasnt "task.sh never reaches for --force" "push --force" "$(cat "$ROOT/bin/task.sh")"
# No origin at all: still commits, never fails the caller.
git -C "$d/.claude" remote remove origin
printf 'more\n' >> "$WC/plan.md"
out="$(t commit "save: no origin")"
is "commit with no origin exits 0" "$(trc commit "save: still no origin")" "0"
has "and says it committed locally only" "locally only" "$out"

# ---------------------------------------------------------------------------------------------
section "19. bin/setup_apply.sh"
d="$(newproj apply shared single)"
out="$(cd "$d" && .claude/bin/setup_apply.sh 2>&1)"
has "shared installs the merge driver" "union merge driver installed and verified" "$out"
[[ -f "$d/.claude/.gitattributes" ]] && ok "the driver file is in the docs repo" || bad "the driver file is in the docs repo"
is "decisions.md union-merges after setup_apply" \
   "$(git -C "$d/.claude" check-attr merge -- work/decisions.md | sed 's/.*: //')" "union"
is "traps.md still does not" \
   "$(git -C "$d/.claude" check-attr merge -- work/traps.md | sed 's/.*: //')" "unspecified"
is "bin/ is executable afterwards" "$( [[ -x "$d/.claude/bin/task.sh" ]] && echo yes )" "yes"
# --dry-run is the safe read: it must change nothing at all.
d="$(newproj applydry solo single)"
before="$(cd "$d/.claude" && git status --porcelain; cd "$d" && git status --porcelain)"
out="$(cd "$d" && .claude/bin/setup_apply.sh --dry-run 2>&1)"
after="$(cd "$d/.claude" && git status --porcelain; cd "$d" && git status --porcelain)"
is "--dry-run changes nothing" "$after" "$before"
has "--dry-run says what it would do" "would " "$out"
[[ -f "$d/CLAUDE.md" ]] && bad "--dry-run wrote the root CLAUDE.md" || ok "--dry-run wrote no root CLAUDE.md"
# A .claude/ with no origin has nowhere for /save to push, which fails at the worst moment.
git -C "$d/.claude" remote remove origin
(cd "$d" && .claude/bin/setup_apply.sh >/dev/null 2>&1) && bad "setup_apply refuses with no origin" \
    || ok "setup_apply refuses with no origin"

# ---------------------------------------------------------------------------------------------
section "20. bin/add_person.sh — solo, then shared"
d="$(newproj addperson solo single)"
(cd "$d" && .claude/bin/setup_apply.sh >/dev/null 2>&1)
(cd "$d/.claude" && git add -A && git commit -qm "setup: solo")
ap() { (cd "$d" && .claude/bin/add_person.sh "$@" 2>&1); }
aprc() { (cd "$d" && .claude/bin/add_person.sh "$@" >/dev/null 2>&1); echo $?; }
is "fewer than two people is refused" "$(aprc ada@example.com ada Ada)" "1"
is "an address that is not this session's is refused" \
   "$(aprc nobody@nowhere.io x X grace@example.org grace Grace)" "1"
printf 'dirty\n' > "$d/.claude/work/traps.md"
is "a dirty docs tree is refused" "$(aprc ada@example.com ada "Ada Lovelace" grace@example.org grace "Grace Hopper")" "1"
(cd "$d/.claude" && git checkout -q -- work/traps.md)
out="$(ap ada@example.com ada "Ada Lovelace" grace@example.org grace "Grace Hopper")"
has "the restore names what came back" "restored from" "$out"
for f in work/collab.md work/collab_settled.md work/owners.txt gitattributes.multi-writer skills-optional work/meetings; do
    [[ -e "$d/.claude/$f" ]] && ok "add_person restored $f" || bad "add_person restored $f"
done
has "owners.txt carries both people" "grace@example.org" "$(cat "$d/.claude/work/owners.txt")"
has "and the existing owner too" "ada@example.com" "$(cat "$d/.claude/work/owners.txt")"
is "owners.txt is tab-separated" \
   "$(grep -c $'\t' "$d/.claude/work/owners.txt")" "2"
is "PEOPLE is flipped" "$(grep '^PEOPLE=' "$d/.claude/project.conf")" 'PEOPLE="shared"'
is "the merge driver is verified" \
   "$(git -C "$d/.claude" check-attr merge -- work/decisions.md | sed 's/.*: //')" "union"
has "the live task is under its owner now" "work/ada/current" "$out"
[[ -d "$d/.claude/work/ada/current" ]] && ok "work/ada/current exists" || bad "work/ada/current exists"
[[ -e "$d/.claude/work/current" ]] && bad "work/current must be gone" || ok "work/current is gone"
[[ -d "$d/.claude/work/archive" ]] && ok "work/archive/ did not move under an owner" \
    || ok "work/archive/ did not move under an owner"
[[ -d "$d/.claude/work/ada/archive" ]] && bad "work/archive/ moved under an owner" || ok "work/archive/ stayed put"
got="$(cd "$d" && . .claude/hooks/lib.sh && load_conf && resolve_owner && echo "$WORK_CURRENT")"
is "resolve_owner now gives the per-owner path" "$got" "work/ada/current"
has "the CLAUDE.md sections to restore are named" "restore these CLAUDE.md sections by hand" "$out"
is "add_person commits nothing" "$(cd "$d/.claude" && git log --oneline -1 --format=%s)" "setup: solo"
is "running it again on a shared install is refused" \
   "$(aprc ada@example.com ada Ada grace@example.org grace Grace)" "1"

# ---------------------------------------------------------------------------------------------
section "21. the scripts own the mechanics, not the skill prose"
# Every task skill drives the lifecycle through bin/task.sh. A skill that spells the steps out
# again is a second implementation that drifts, and nothing compares the two.
missing="$(grep -L 'bin/task.sh' "$ROOT"/skills/{start,save,load,park,done}/SKILL.md 2>/dev/null \
           | sed "s|$ROOT/||" | tr '\n' ' ')"
is "every task skill calls bin/task.sh" "${missing:-none}" "none"

summary
