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
VERBOSE=0
[[ "${1:-}" == "-v" ]] && VERBOSE=1

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
         gitattributes.multi-writer skills skills-optional hooks checks codex work reference
         output-styles)
scan() { grep -rniE "$1" "${SHIPPED[@]/#/$ROOT/}" 2>/dev/null || true; }

pass=0; fail=0
ok()   { pass=$((pass+1)); [[ $VERBOSE -eq 1 ]] && printf '  ok    %s\n' "$1"; return 0; }
bad()  { fail=$((fail+1)); printf '  FAIL  %s\n' "$1"; [[ -n "${2:-}" ]] && printf '        %s\n' "$2"; return 0; }
is()   { [[ "$2" == "$3" ]] && ok "$1" || bad "$1" "expected [$3], got [$2]"; }
has()  { grep -q "$2" <<<"$3" && ok "$1" || bad "$1" "missing: $2"; }
hasnt(){ grep -q "$2" <<<"$3" && bad "$1" "unexpected: $2" || ok "$1"; }
section() { printf '\n%s\n' "$1"; }

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
# What /setup does, verbatim from its step 5.
(cd "$d" && git check-ignore -q .claude || printf '\n.claude/\n' >> .gitignore)
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

# ---------------------------------------------------------------------------------------------
section "8. park and unpark round trip"
d="$(newproj park shared multi)"
eval "$(cd "$d" && . .claude/hooks/lib.sh && load_conf && resolve_owner && echo "WC=$WORK_CURRENT; WP=$WORK_PARKED")"
cd "$d/.claude" || { bad "cannot enter the park fixture"; return 1 2>/dev/null || exit 1; }
mkdir -p "$WC"
printf '# Plan\n- [ ] a\n' > "$WC/plan.md"
printf '# Next session\n**Blocked on:** PR #482 merging\n' > "$WC/handoff.md"
# /park §4
mkdir -p "$WP"; mv "$WC" "$WP/api-rename"; mkdir -p "$WC"
is "park empties the live directory" "$(ls -A "$WC" | wc -l | tr -d ' ')" "0"
out="$(cd "$d" && .claude/hooks/session_brief.sh)"
has "the brief lists the parked task" "parked: api-rename" "$out"
has "the brief shows its blocker" "PR #482 merging" "$out"
# /load §0.5 — the rmdir is what stops the task nesting one level down
rmdir "$WC" 2>/dev/null; mv "$WP/api-rename" "$WC"
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
out="$(cd "$d" && env CLAUDE_CODE_REMOTE= .claude/hooks/cloud_setup.sh 2>&1 || true)"
has "cloud_setup refuses off a container" "not a cloud session" "$out"
(cd "$d" && .claude/checks/cloud_ready.sh >/dev/null 2>&1) && ok "cloud_ready passes on a clean install" \
    || bad "cloud_ready passes on a clean install"
out="$(cd "$d" && .claude/checks/cloud_ready.sh 2>&1)"
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
# -f because the fixture modified owners.txt after cloning, and plain `git rm` refuses on a
# modified file. Without it the removals silently do not happen and everything below passes
# vacuously — which is exactly what this suite did until the check two lines down was added.
(cd "$d/.claude" && git rm -qrf work/collab.md work/collab_settled.md work/owners.txt \
                                gitattributes.multi-writer skills-optional work/meetings)
still="$(cd "$d/.claude" && ls -d work/collab.md work/collab_settled.md work/owners.txt \
         gitattributes.multi-writer skills-optional work/meetings 2>/dev/null || true)"
is "the removal actually removed everything" "${still:-gone}" "gone"
out="$(cd "$d" && .claude/hooks/session_brief.sh 2>&1)"
hasnt "session_brief does not error after the removal" "No such file" "$out"
has "session_brief still reports" "No active task" "$out"
(cd "$d" && .claude/checks/cloud_ready.sh >/dev/null 2>&1) && ok "cloud_ready still passes" || bad "cloud_ready still passes"
got="$(cd "$d" && . .claude/hooks/lib.sh && load_conf && resolve_owner && echo "$WORK_CURRENT")"
is "paths still resolve with no owners.txt" "$got" "work/current"
out="$(printf '{"tool_input":{"command":"git push --force"}}' | "$d/.claude/hooks/block_env_commands.sh" 2>&1; echo "rc=$?")"
has "the command hook still blocks" "rc=2" "$out"
(cd "$d" && .claude/codex/check_bridge.sh >/dev/null 2>&1) && ok "codex bridge still validates" || bad "codex bridge still validates"

# session_brief and cloud_setup DO name owners.txt, and that is correct — they read it only when
# PEOPLE=shared. What matters is that every executable still runs clean with the file absent, so
# assert behaviour rather than the absence of a mention: a script may refer to a file it tolerates.
for h in "$d"/.claude/hooks/*.sh "$d"/.claude/checks/*.sh; do
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
for h in "$d"/.claude/hooks/*.sh "$d"/.claude/checks/*.sh; do
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
# What /setup does, verbatim from its step 5.
outfile="$TMP/rootclaude.md"
sed -e "s|<PROJECT>|myproject|" -e "s|<DOCS_REPO_URL>|git@example.com:me/myproject-claude.git|" \
    "$ex" > "$outfile"
hasnt "no placeholder survives substitution" "<PROJECT>\|<DOCS_REPO_URL>" "$(cat "$outfile")"
has "the result names the project" "myproject" "$(cat "$outfile")"
has "the result carries the clone command" "git clone git@example.com" "$(cat "$outfile")"

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

printf '\n%s\n' "----------------------------------------"
printf 'passed %s, failed %s\n' "$pass" "$fail"
exit $(( fail > 0 ))
