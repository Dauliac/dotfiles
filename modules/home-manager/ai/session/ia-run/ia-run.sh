#!/usr/bin/env bash
# ia-run — pane-side helper for herdr-run.
#
# Runs a base64-encoded command wrapped in colored, bold BEGIN / END
# markers that (a) look nice for the human watching the pane, and
# (b) give the client (herdr-run) unambiguous line-start patterns to
# match on for `herdr pane wait-output` and awk extraction.
#
# Interface:
#   ia-run <marker_id> <base64_cmd>
#
# Pane output looks like:
#   ▶ ia-run [4f7a2b] $ cargo build
#       <command's own output flows here>
#   ■ ia-run [4f7a2b] exit 0 (took 0.19s)
#
# The command runs under `sh -c` so it keeps the pane's TTY —
# sudo/y-N/git-rebase-i work naturally, the human types in the pane.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: ia-run <marker_id> <base64_cmd>" >&2
  exit 2
fi

MARKER="$1"
CMD_B64="$2"

if ! CMD=$(printf '%s' "$CMD_B64" | base64 -d 2>/dev/null); then
  echo "ia-run: could not base64-decode command payload" >&2
  exit 3
fi

# Compact one-line preview of the command for the BEGIN marker line —
# collapse newlines, squeeze spaces, truncate over 200 chars.
CMD_PREVIEW=$(printf '%s' "$CMD" | tr '\n' ' ' | tr -s ' ' | sed 's/[[:space:]]*$//')
if (( ${#CMD_PREVIEW} > 200 )); then
  CMD_PREVIEW="${CMD_PREVIEW:0:197}…"
fi

# ANSI palette when stdout is a TTY (herdr panes always give us one).
if [[ -t 1 ]]; then
  bold=$'\e[1m'
  green=$'\e[32m'
  cyan=$'\e[36m'
  red=$'\e[31m'
  dim=$'\e[2m'
  reset=$'\e[0m'
else
  bold=''; green=''; cyan=''; red=''; dim=''; reset=''
fi

# BEGIN marker — the ▶ + "ia-run [marker]" prefix is line-anchored so
# the client's awk extractor finds it deterministically.
printf '%s%s▶ ia-run [%s]%s %s$%s %s\n' \
  "$bold" "$cyan" "$MARKER" "$reset" "$dim" "$reset" "$CMD_PREVIEW"

start=$SECONDS
rc=0
sh -c "$CMD" || rc=$?
elapsed=$((SECONDS - start))

if (( rc == 0 )); then
  color="$green"
else
  color="$red"
fi
printf '%s%s■ ia-run [%s]%s exit %d (took %ds)\n' \
  "$bold" "$color" "$MARKER" "$reset" "$rc" "$elapsed"

exit "$rc"
