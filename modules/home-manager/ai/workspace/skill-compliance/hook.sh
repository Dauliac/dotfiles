#!/usr/bin/env bash
# UserPromptSubmit hook — layered on top of the enterprise
# "MANDATORY SKILL ACTIVATION SEQUENCE" hook that ships via
# remote-settings.json. That upstream hook is enforceable only in prose;
# in practice agents collapse the enumeration to "No skills needed" and
# skip surface-level word-matches (see the herdr-run / cargo build miss).
#
# This addendum closes the single loophole that mattered:
#   "if any word in the user's prompt appears in a skill's description
#    or trigger list, that skill MUST be marked YES with the matching
#    phrase quoted verbatim".
#
# Bypass in a session where the enterprise hook is already noisy enough:
#   XI_DISABLE_SKILL_COMPLIANCE_HOOK=1
#
# Stdout goes directly into the model's context as UserPromptSubmit hook
# output, sitting after the enterprise MANDATORY sequence and before the
# user's prompt is processed.
set -euo pipefail

if [[ -n "${XI_DISABLE_SKILL_COMPLIANCE_HOOK:-}" ]]; then
  exit 0
fi

cat <<'EOF'
COMPLIANCE ADDENDUM to the MANDATORY SKILL ACTIVATION SEQUENCE above.

Word-match self-check — MANDATORY before Step 2:

Scan every word in the user's most recent prompt against each skill's
description and its listed trigger phrases. If a word matches, that
skill is YES with the matching phrase QUOTED VERBATIM as the reason.
This applies literally, not semantically — no "adjacent to", no
"somewhat related", no "the user probably means".

Examples of matches that MUST fire:
  - prompt contains "run" AND a skill lists "run" as a trigger
    -> that skill: YES ("prompt says 'run', description lists 'run'")
  - prompt contains "build" AND a skill's description mentions
    build as a category ("for every build", "builds/tests/…")
    -> that skill: YES ("prompt says 'build', description mentions build")
  - prompt says "cargo build" AND a skill covers "every build"
    -> that skill: YES — decide from the prompt, NOT from the anticipated
       command output. "It'll probably be a no-op" is not a valid reason
       to skip: you cannot know that before running.

Forbidden shortcut phrases in Step 1:
  - "No skills needed for a simple <X> command"
  - "All other skills: NO — unrelated"    (must be per skill, one line each)
  - Any collapse of the enumeration that hides a YES you would have
    written out on its own line.

If a YES emerges from the word-match check, Step 2 ACTIVATE is required.
Skipping Step 2 after a YES in Step 1 is a policy violation.

Enumeration must be complete: for every YES you write out on its own
line, Step 2 must call the corresponding Skill() tool. No implicit
"already loaded" excuses — call the tool.
EOF
