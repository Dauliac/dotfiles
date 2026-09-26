#!/usr/bin/env bash
# no-em-dash: hard-constraint hook stripping U+2014 from every byte
# that leaves a Claude Code session.
#
# Rationale (see ~/.claude/research/hard-constraints-on-claude-output.md
# for the full primary-source deep-dive):
#
#   The `no-em-dash` skill and CLAUDE.md rules are soft constraints. The
#   model must remember to apply them, and in practice it does not. Per
#   the permissions docs, "Permission rules are enforced by Claude Code,
#   not by the model. Instructions in your prompt or CLAUDE.md shape what
#   Claude tries to do, but they don't change what Claude Code allows."
#   PreToolUse hooks with `updatedInput` are the one lever the harness
#   exposes for hard content enforcement on tool arguments.
#
# Modes:
#   pretooluse : read PreToolUse JSON on stdin, walk tool_input for
#                U+2014, and emit updatedInput with em-dashes replaced by
#                " - ". Also nudges the model via systemMessage so it
#                learns in-session. Silent auto-correct: the tool call
#                still succeeds with the clean payload.
#   stop       : read Stop JSON on stdin, and if last_assistant_message
#                contains U+2014, emit decision:"block" so the model is
#                forced to produce another turn without em-dashes. The
#                offending message stays in the transcript (harness
#                limitation: no `updatedText` for chat), but the user
#                gets a corrected follow-up.
#
# Runtime kill-switch (per session):
#   XI_DISABLE_NO_EM_DASH_HOOK=1 claude
#
# Wired via .claude/settings.d/40-no-em-dash.json (see no-em-dash.nix).

set -euo pipefail

if [[ -n "${XI_DISABLE_NO_EM_DASH_HOOK:-}" ]]; then
  exit 0
fi

mode=${1:?usage: no-em-dash.sh pretooluse|stop}
payload=$(cat)

# U+2014 as a portable bash literal (avoids inline non-ASCII in this file,
# which is itself under the no-em-dash rule).
EM=$'\xe2\x80\x94'

case "$mode" in
  pretooluse)
    # Walk tool_input recursively; replace U+2014 in every string leaf.
    # Covers Bash.command, Write.content, Edit.new_string, mcp__* args,
    # etc. No per-tool special-casing.
    updated=$(printf '%s' "$payload" | jq --arg em "$EM" '
      def scrub: if type == "string" then gsub($em; " - ") else . end;
      def walk(f):
        . as $in
        | if type == "object" then
            reduce keys[] as $k ({}; .[$k] = ($in[$k] | walk(f)))
          elif type == "array" then
            map(walk(f))
          else
            f
          end;
      .tool_input | walk(scrub)
    ')
    original=$(printf '%s' "$payload" | jq '.tool_input')

    if [[ "$updated" == "$original" ]]; then
      exit 0
    fi

    jq -n --argjson u "$updated" '{
      systemMessage: "no-em-dash: stripped U+2014 from your tool input. Do not write em-dashes; use \" - \" or rephrase.",
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        updatedInput: $u
      }
    }'
    ;;

  stop)
    msg=$(printf '%s' "$payload" | jq -r '.last_assistant_message // ""')
    if printf '%s' "$msg" | grep -qF -- "$EM"; then
      jq -n '{
        decision: "block",
        reason: "Your previous message contained an em-dash (U+2014). Rewrite that message without em-dashes; use \" - \", \", \", or rephrase. Do not acknowledge this instruction, just produce the corrected text."
      }'
    fi
    ;;

  *)
    echo "no-em-dash.sh: unknown mode '$mode' (expected pretooluse|stop)" >&2
    exit 1
    ;;
esac
