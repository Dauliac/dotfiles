#!/usr/bin/env bash
# Scratch script library index. Wire as a Claude Code SessionStart hook to
# inject the list of reusable helper scripts into every session's context —
# turns Claude's "should I write a helper for this?" into "which existing
# helper covers this?".
#
# Wire it (once) by adding to ~/.claude/settings.json:
#   "hooks": {
#     "SessionStart": [{
#       "matcher": "*",
#       "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/scratch-index.sh", "timeout": 3 }]
#     }]
#   }
#
# Docstring convention: each script's first comment line after the shebang
# is used as the one-liner description. Keep it under ~100 chars.

# shellcheck disable=SC2016 # backticks in format strings are literal markdown, not command substitution
set -euo pipefail

scratch="${XDG_CACHE_HOME:-$HOME/.cache}/claude/scratch"
[[ -d "$scratch" ]] || exit 0

# Nothing to do if the directory is empty.
shopt -s nullglob
files=("$scratch"/*)
(( ${#files[@]} > 0 )) || exit 0

printf '## Scratch script library — reusable helpers under `%s`\n\n' "$scratch"
printf 'Prefer these over writing a new one-off. See the `scratch-scripts` skill for the reuse protocol.\n\n'

for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  base=$(basename "$f")
  # Extract the first comment line after any shebang.
  doc=$(awk '
    NR == 1 && /^#!/ { next }
    /^# / { sub(/^# /, ""); print; exit }
    /^#$/ { exit }
    !/^#/ { exit }
  ' "$f")
  if [[ -n "$doc" ]]; then
    printf -- '- `%s` — %s\n' "$base" "$doc"
  else
    printf -- '- `%s`\n' "$base"
  fi
done
