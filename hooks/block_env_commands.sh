#!/usr/bin/env bash
# PreToolUse(Bash) — refuse the commands you run yourself, and warn on the ones that reach outside
# this machine.
#
# Prose rules get violated; exit 2 doesn't. This is the one hook that changes what the agent can do,
# so it is also the one worth keeping short enough to read in full.
#
# THREE TIERS, because two is not enough:
#
#   ALLOW  checked first, and wins. Read-only lookups that merely resemble a blocked command.
#   WARN   proceeds, but prints a notice the agent has to read. For actions that are legitimate
#          when you asked for them and a mistake when you didn't — `git push` is the whole reason
#          this tier exists. A hard block here would be wrong (you do ask for pushes) and silence
#          would be wrong too (an unasked push is already outside the repo when you notice).
#   BLOCK  exit 2. The agent cannot proceed and is told why.
#
# EDIT THE PATTERNS BELOW. They ship as examples spanning several ecosystems, not as a policy —
# every project reserves different commands, and a hook that blocks nothing is a hook that fails
# silently. /setup asks which commands you run yourself and fills these in.
#
# Test:  echo '{"tool_input":{"command":"git push --force"}}' | .claude/hooks/block_env_commands.sh; echo "exit $?"

set -uo pipefail

INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)"
[[ -z "$CMD" ]] && exit 0

# --- ALLOW: checked first, wins over everything ---------------------------------------------------
# Read-only inspection that resembles a blocked or warned command. Leave as '^$' if there are none.
ALLOW='(^|[^[:alnum:]_./-])git[[:space:]]+(push[[:space:]]+--dry-run|remote|log|status|diff)'
ALLOW+='|(^|[^[:alnum:]_./-])(gh|glab)[[:space:]]+[a-z-]+[[:space:]]+(list|view|status)'
ALLOW+='|(^|[^[:alnum:]_./-])(npm|pnpm|yarn)[[:space:]]+(view|info|ls)'
# A dry run publishes nothing. Blocking it is a false positive, and false positives are how a hook
# ends up disabled — which costs you every real block it would have caught.
ALLOW+='|(^|[^[:alnum:]_./-])(npm|cargo|poetry|gem)[[:space:]]+publish[[:space:]]+--dry-run'

# --- WARN: allowed, but never silently ------------------------------------------------------------
# Anything that writes to a remote, a shared environment, or someone else's inbox.
WARN='(^|[^[:alnum:]_./-])git[[:space:]]+push([^[:alnum:]_-]|$)'
WARN+='|(^|[^[:alnum:]_./-])(gh|glab)[[:space:]]+(pr|mr|issue)[[:space:]]+(create|merge|close|comment)'

# --- BLOCK: exit 2 ---------------------------------------------------------------------------------
# 1. Force-pushes. They destroy remote history, and no amount of "I was asked to" makes that
#    recoverable for someone who has already fetched. This one is worth keeping in every project.
BLOCK='(^|[^[:alnum:]_./-])git[[:space:]]+push([^#]*)(--force([^[:alnum:]_-]|$)|--force-with-lease|[[:space:]]-f([[:space:]]|$))'
BLOCK+='|(^|[^[:alnum:]_./-])git[[:space:]]+(reset[[:space:]]+--hard[[:space:]]+origin|clean[[:space:]]+-[a-z]*f)'

# 2. Publishing to a package registry. Irreversible on most of them, and never something an agent
#    should reach on its own. Examples across ecosystems — delete the ones you don't use.
BLOCK+='|(^|[^[:alnum:]_./-])npm[[:space:]]+publish([^[:alnum:]_-]|$)'
BLOCK+='|(^|[^[:alnum:]_./-])(cargo|poetry|gem)[[:space:]]+publish([^[:alnum:]_-]|$)'
BLOCK+='|(^|[^[:alnum:]_./-])twine[[:space:]]+upload'
BLOCK+='|(^|[^[:alnum:]_./-])(gh|glab)[[:space:]]+release[[:space:]]+(create|delete|upload|edit)'

# 3. YOUR commands — the ones you run yourself, that the agent must not. Deploys, long simulations,
#    anything that costs money or touches production. These ship as placeholders; replace them.
BLOCK+='|(^|[^[:alnum:]_./-])(make[[:space:]]+deploy|docker[[:space:]]+compose[[:space:]]+up)([^[:alnum:]_-]|$)'
BLOCK+='|(^|[^[:alnum:]_./-])(terraform|kubectl)[[:space:]]+(apply|destroy|delete)'
BLOCK+='|\./deploy\.sh'

if grep -qE "$ALLOW" <<<"$CMD"; then
    exit 0
fi

if grep -qE "$BLOCK" <<<"$CMD"; then
    cat >&2 <<EOF
BLOCKED by .claude/hooks/block_env_commands.sh

  $CMD

This is a command the project reserves for a human, or one whose effects cannot be undone.
Do not look for another way to run it. Say what you wanted to run and why, and let the user
run it themselves.
EOF
    exit 2
fi

if grep -qE "$WARN" <<<"$CMD"; then
    cat >&2 <<EOF
NOTICE from .claude/hooks/block_env_commands.sh

This command writes somewhere outside this machine:

  $CMD

Allowed to proceed, but only because the user asked for it. The standing rule is: don't commit
or push unless asked. If you were not explicitly asked to do this, stop and confirm first.
EOF
    exit 0
fi

exit 0
