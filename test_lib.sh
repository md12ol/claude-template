#!/usr/bin/env bash
# Assertion helpers shared by test.sh and test_fixture.sh. Source it; do not run it.
#
#     . "$(dirname "${BASH_SOURCE[0]}")/test_lib.sh"
#
# ok/bad count; is/has/hasnt compare; summary prints the totals and returns 1 on any failure.
VERBOSE="${VERBOSE:-0}"
pass=0; fail=0
ok()    { pass=$((pass+1)); [[ $VERBOSE -eq 1 ]] && printf '  ok    %s\n' "$1"; return 0; }
bad()   { fail=$((fail+1)); printf '  FAIL  %s\n' "$1"; [[ -n "${2:-}" ]] && printf '        %s\n' "$2"; return 0; }
is()    { [[ "$2" == "$3" ]] && ok "$1" || bad "$1" "expected [$3], got [$2]"; }
has()   { grep -q "$2" <<<"$3" && ok "$1" || bad "$1" "missing: $2"; }
hasnt() { grep -q "$2" <<<"$3" && bad "$1" "unexpected: $2" || ok "$1"; }
section() { printf '\n%s\n' "$1"; }
summary() {
    printf '\n%s\n' "----------------------------------------"
    printf 'passed %s, failed %s\n' "$pass" "$fail"
    return $(( fail > 0 ))
}
