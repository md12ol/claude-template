#!/usr/bin/env bash
# Mechanical pre-review audit of ONE file's comments. Run it before showing a comment-heavy diff to
# a person: every hit is a shape comment_style.md already forbids, and finding them by hand is the
# cost this replaces.
#
#     .claude/bin/comment_audit.sh src/thing.ext
#
# Heuristic on purpose, and language-neutral: it treats `//`, `#`, `--`, `/* */` and `"""` as
# comment openers, so a hash inside a string can show up as a hit. A false positive costs a glance;
# a missed narration comment costs a review round. It never fails a build. Findings exit 0, and the
# only refusal is a file it cannot read. This script is full of the literal shapes it looks for, so
# running it on itself reports plenty; run it on the file you are reviewing.
#
# Test:  .claude/bin/comment_audit.sh .claude/hooks/lib.sh

set -uo pipefail

file="${1:-}"
[[ -n "$file" && -r "$file" && -f "$file" ]] \
    || { echo "comment_audit: needs one readable file; usage: comment_audit.sh <file>" >&2; exit 1; }

# Comment-looking lines only, numbered. Everything below greps this rather than the whole file.
comments() { grep -nE '(^|[[:space:]])(//|#|--|/\*|\*/|""")' "$file"; }

hits=0
report() {  # report <label> <extended-regex>
    local label="$1" ere="$2" found
    found="$(comments | grep -inE "$ere")"
    [[ -n "$found" ]] || return 0
    hits=$((hits + 1))
    printf '  [%s]\n' "$label"
    sed 's/^/    /' <<<"$found"
}

report "narrates the next line: delete it, or rename the thing it describes" \
       '(//|#|--)[[:space:]]*(increment|decrement|initiali[sz]e|instantiate|loop over|iterate over|call the|return the|set the|get the|add one|create a|now we|then we)\b'

report "count or roll-call that rots: say each, every, all of them" \
       '\b(two|three|four|five|six|seven|eight|nine|ten|both|all [a-z]+) (of the|supported|possible|required|shipped|cases|callers|places|steps|fields|kinds|modes|backends|strategies)\b'

report "pointer to a document a downstream reader cannot open: state the reason itself" \
       '(see|per|cf\.?|as agreed in) [A-Za-z0-9_./-]+\.(md|txt|docx|xlsx|pdf)|\bdesign doc\b|§[0-9]'

report "describes a state of the world: say what the thing is for" \
       '(currently (unused|unsupported|broken|disabled)|for now|will be (replaced|removed|rewritten)|temporary until)'

report "looks like commented-out code" \
       '(//|#|--)[[:space:]]*([A-Za-z_][A-Za-z0-9_.]*\(.*\)[[:space:]]*;[[:space:]]*$|(if|for|while|return|def|fn|func|function|let|var|const|import|print|echo)[[:space:]]*[({"'"'"']|[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[^=].*;[[:space:]]*$)'

[[ $hits -eq 0 ]] && echo "  clean: $file"

# <!-- FILL IN — the shapes that keep coming back in THIS project's reviews.
#
# One `report` line each, in the same form as the generic ones above: a label naming what to do
# instead, then an extended regex. The ones worth adding are the corrections a reviewer here has
# had to write twice.
#
#   report "US spelling in prose"        '\bbehavior\b|\bcolor\b|\bneighbor'
#   report "a term this project retired" '<the old word>'
#   report "cites the design document"   '<its filename>'
# -->

exit 0
