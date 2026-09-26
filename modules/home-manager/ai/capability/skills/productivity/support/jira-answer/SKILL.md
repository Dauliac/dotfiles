---
name: jira-answer
description: Ticket answer phase — write a very short, PLAT-team-voice reply to the reporter, based on proof.md + fix.md. Posts the reply through `twg jira workitem comment create --issue-id KEY --body '...' --body-format markdown` (correct auth, @mentions the reporter) after explicit user OK; optionally transitions the support ticket to Done via `twg jira workitem update --status Done`; when the reply shape is "Need more info" (asking the reporter a question) it ALSO transitions the ticket to `Waiting for customer` so the queue reflects that the ball is in the reporter's court, and the async-wait wake-back moves it out of `Waiting for customer` (back to `In Progress`) as soon as the reporter replies. **Uses the warm Dust conversation as an accuracy + tone reviewer** — the same conversationId that has heard the whole story (ticket, proof, fix, alternatives) since setup; asks Dust to check the draft against the calibrated PLAT voice sample and against what actually happened before the operator sees it. Trigger on "write the ticket answer", "draft the Jira reply", "close-out comment for PLAT-1234", or as the third phase called by the `jira-ticket` orchestrator after `jira-fix`. Output is a draft under $ticket_dir/answer.md — never posts without explicit user OK. Distinct from generic `twg jira workitem comment create` (used for arbitrary internal notes): this one is the reporter-facing close-out and matches the observed PLAT close-out style (short, warm-collegial, action-oriented, verifiable).
---

# jira-answer — short, PLAT-style reply to the reporter

**DOR/DOD gates:** see `jira-ticket/references/dor-dod.md` §
`phase:answer` and `phase:close`. `phase:close` DOR is
non-negotiable: MR merged, merge pipeline success, prod deploy job
success, capability set, zero open rollback beads — all five verified
programmatically via API, never by trusting bead state. Run
`close_dor_check` from the contract before transitioning to Done.

**IMPORTANT — the reporter sees only what you post here.** Everything
you learned, tried, ruled out, or half-figured-out stays in
`$ticket_dir/{proof,fix}.md` and bead notes. The Reply is the
minimum the reporter needs to act or verify — nothing else.

Draft the reply the reporter will actually read. Short. Warm. Direct.
Match the observed PLAT team voice (calibration step below) — not a
military runbook. The reporter is a colleague, not a soldier.

## When to reach for it

- `jira-explore` and `jira-fix` have produced their outputs.
- The user asks "write the reply", "draft the Jira comment", "how
  should I answer the reporter".

## Inputs

- `$ticket_dir/proof.md`
- `$ticket_dir/fix.md`
- Per-ticket bead + Dust conversation ID (for context, not for the
  reply).

## Output: `$ticket_dir/answer.md`

The file has three sections. The **Reply** section is what gets
posted. The other two are staging for the human — they never appear
in Jira.

```markdown
# <TICKET-ID> — Reply Draft

## Reply (post this)

<the short answer — see rules below>

## Context (for the poster, not the reporter)

- Proof: $ticket_dir/proof.md
- Fix: $ticket_dir/fix.md
- MR / commit / config change:
- Bead: <bd id>
- Dust conversation: <cid>

## What to do next

<instructions for the human posting the reply — e.g. "post reply,
then close as Done", "post reply, keep open pending MR merge">
```

## Calibration — read the last 3 PLAT close-outs BEFORE drafting

The PLAT team has an established voice. Match it. Before writing the
Reply, sample the last 3 done-tickets from the support project and
read their final human-written comments:

```bash
# List 5 recent Done tickets in the support project
twg jira workitem query \
  --jql 'project = PLAT AND status = Done ORDER BY updated DESC' \
  --limit 5 -o json \
  | jq -r '.. | objects | select(.key? and (.key | startswith("PLAT-"))) | .key'

# For each of the top 3, dump the full comment thread — read the
# LAST human comment (not the "Automation for Jira" 7-day bot ping)
for K in <KEY1> <KEY2> <KEY3>; do
  jiraai-review "$K"     # or the curl recipe from that skill
done
```

Cache the calibration in `$ticket_dir/voice.md` so subsequent phases
(and future sessions) do not re-fetch:

```bash
{ echo "# PLAT voice samples ($(date +%F))"; \
  for K in <KEY1> <KEY2> <KEY3>; do
    echo ""; echo "## $K"; echo "";
    jiraai-review "$K" | sed -n '/-- Comments/,$p'
  done; } > "$ticket_dir/voice.md"
```

## Observed PLAT reply style (2026-09 sample)

Distilled from real close-outs on PLAT — treat as living guidance,
refresh via calibration on every ticket:

1. **Greet the reporter by @mention** on line 1: `Hello @<Reporter>,`
   (Jira ADF `mention` mark). Warm, not military.
2. **1 to 3 sentences.** "Done everywhere." / "It's fixed!" /
   "Manomano STG deleted." — real observed replies. If it is longer
   than 3 sentences, the details belong in a link, not the comment.
3. **Say what changed + where** with an inline link to the MR /
   pipeline / config change (ADF `link` mark). Paths / commands /
   error strings in `code` marks.
4. **Invite verification** on the last line when the ticket needs the
   reporter to confirm: "could you check please?", "please verify
   after pipeline finishes", "you can close the ticket". Do not close
   the ticket for them — let them.
5. **Numbers over adjectives.** "Fixed in v2.14.3, deployed today at
   14:20 UTC" beats "recently deployed".
6. **No process narration.** No "I checked the pod logs, then looked
   at the deploy, and found…". The reporter does not need the trail.
7. **No hedging, no apology.** "It's fixed" beats "I believe it
   should now be fixed, please confirm if it isn't". A quiet,
   inviting "could you check please?" replaces defensive hedging.
8. **Warm is fine, marketing is not.** Emojis are acceptable in
   moderation (the team uses them). "I hope this helps",
   "Please note that", "We are pleased to inform you" — cut.
9. **The auto-bot pings after 7 days of silence.** If the ticket is
   waiting on the reporter, an early explicit "waiting on you for
   <thing>" avoids the automation nag.

The `ste100` skill's spirit (short, direct, no fluff) still applies;
its strict military tone does not. If you find yourself writing a
runbook step, you are in the wrong doc — that goes in `fix.md`.

## Answer shapes

The right shape depends on the ticket's fate. Pick one:

**Fixed** (fix has landed):

```text
Hello @<Reporter>,
Fixed in !<MR-IID> (deployed to <env> at <YYYY-MM-DD HH:MM UTC>).
Could you check please and close the ticket if it works on your side?
```

**Fix in flight** (MR open, not merged):

```text
Hello @<Reporter>,
Root cause: <one line>. Fix in !<MR-IID>, ETA <env> <YYYY-MM-DD>.
<Workaround in one sentence, if any.> I'll ping you when it lands.
```

**Won't fix** (out of scope, by design, duplicate):

```text
Hello @<Reporter>,
This is a duplicate of <KEY> / by design / owned by @<other-team>.
See <link>. <One-line alternative action.> Reopen with new evidence
if that link does not cover it.
```

**Need more info** (blocked on reporter):

```text
Hello @<Reporter>,
I can't reproduce with what's in the ticket. Could you share:
- <exact command / URL / timestamp>
- <log line / trace ID>
- <environment>
```

The "Need more info" shape ALSO transitions the ticket status to
**Waiting for customer** after the comment posts (see method
step 11b) — the status itself signals that the ball is in the
reporter's court, so the "Ticket stays open until then" trailer
that used to close this shape is now redundant and gets cut.

All four shapes preserve the observed PLAT structure: `@mention` first
line, 1 fact-anchored middle line, 1 action / invite-verify last line.

## Method

1. **Snapshot for freshness — MANDATORY, before anything else.**
   Capture the ticket's drift-relevant fields (status + last non-me
   comment + assignee) so we can detect a teammate comment or status
   flip landing while we draft. Motivating incident: PLAT-4095
   2026-09 — Vincent's comment invalidated the draft
   mid-flight and the agent posted the stale reply anyway. See
   `jiraai-freshness-check`.

   ```bash
   : "${JIRA_ME_ACCOUNT_ID:=$(twg jira user me -o json | jq -r '.accountId')}"
   export JIRA_ME_ACCOUNT_ID
   freshness_snapshot "$ticket" "$ticket_dir"
   ```

2. **Calibrate** — read the last 3 PLAT close-outs (see Calibration
   block above). Cache into `$ticket_dir/voice.md`. Skip if the file
   already exists and is < 24h old.
3. Read `proof.md` and `fix.md`. Pull the outcome, the fix reference,
   and any action for the reporter.
4. Look up the reporter's accountId once for the `@mention`:

   ```bash
   REPORTER_EMAIL=$(jiraai-review "$ticket" | awk -F': *' \
     '/^Reporter:/ {print $2}')
   REPORTER_ID=$(curl -sS -u "$AUTH" \
     "$ROOT/user/search?query=$REPORTER_EMAIL" | jq -r '.[0].accountId')
   ```

5. Pick a shape (Fixed / In flight / Won't fix / Need info).
6. Draft the Reply — 1 to 3 sentences, PLAT voice (calibration
   applies). Trim ruthlessly. If a line does not help the reporter
   act or verify, cut it.
7. Self-check:
   - Line 1 is `Hello @<Reporter>,` (or the team convention observed
     in `voice.md`).
   - Total ≤ 3 sentences of body.
   - Every link resolves (MR, pipeline, doc).
   - No process narration ("I looked at…", "I ran…", "then I").
   - No hedge words (probably, maybe, might, should be, I think).
   - No apology preamble (sorry for the delay, unfortunately).
   - Numbers where you had adjectives ("v2.14.3, 14:20 UTC" not
     "recently").
8. **Dust review — MANDATORY, before user handoff.** The warm
   conversation has heard the whole story; use it as a second pair
   of eyes on both accuracy and tone. Use the `dust_ask` helper
   defined in `jira-ticket`.

   ```bash
   dust_ask "Draft reply for $ticket, ready to post as a Jira \
comment to the reporter:

<paste the Reply block from answer.md verbatim>

Two questions: (a) accuracy — given everything we did on this \
ticket (proof, fix, MR), is any statement in this reply wrong, \
overclaiming, or hiding a caveat the reporter needs? (b) tone — \
here are the last 3 PLAT close-outs I sampled as calibration \
(from voice.md):

<paste the last human comment from each of the 3 voice.md samples>

Does the draft match that team voice? Suggest concrete edits, or \
say 'good to post'."
   ```

   Fold Dust's edits into `answer.md` before showing it to the
   operator. Log the exchange (already automatic via `dust_ask`).
9. Write `answer.md`. **Do not post.**
10. Hand off to the user:

   ```text
   Draft ready at $ticket_dir/answer.md.
   Shape: <Fixed / In flight / Won't fix / Need info>.
   Post it? (waiting for your OK.)
   ```

11. On user OK, **post via `twg jira workitem comment create`** — it handles auth
   (sops-managed API token) and the correct Jira endpoint. `--body-format markdown`
   lets you pass a raw markdown string (twg converts to ADF); never hand-roll a
   `curl` here.

   ```bash
   # From $ticket_dir, after user typed "post it":
   REPLY=$(awk '/^## Reply/,/^## Context/' answer.md \
     | sed '1d;$d')                          # extract Reply body

   # Freshness gate — snapshot was taken at method step 1.
   # See jiraai-freshness-check. Refuse to post on any drift.
   verdict=$(freshness_diff "$ticket" "$ticket_dir") || case "$verdict" in
     NEW_COMMENTS|BOTH)
       echo "REFUSING to post: new non-me comment landed. See stderr above." >&2
       echo "Re-run jiraai-review, re-draft answer.md, freshness_snapshot, retry." >&2
       exit 10 ;;
     STATUS_CHANGE)
       echo "REFUSING to post: ticket status moved while drafting." >&2
       echo "Re-evaluate whether the reply still applies." >&2
       exit 11 ;;
     ASSIGNEE_CHANGE)
       echo "WARN: assignee changed. Proceeding for ownership-neutral reply." >&2
       echo "For Done/Waiting-for-customer transitions, refuse instead." >&2 ;;
   esac

   twg jira workitem comment create --issue-id "$ticket" \
     --body "$REPLY" --body-format markdown
   ```

   Follow up with a **status transition** if the ticket is done —
   use `twg jira workitem update --id "$ticket" --status Done` (twg resolves the
   right transition ID for the ticket's issue type; see `jiraai` cookbook for
   the raw IDs if you need to `curl` fallback — Story/Task/Bug/Sub-task Done is `41`,
   Bet-Initiative Done is `8`; **PLAT Service Request Done is `2`**).

   **Platform Capability gate — REFUSE Done if unset.** Every DONE
   PLAT ticket in the wild has `customfield_11907` populated; the
   support team treats it as a close-out requirement. Before firing
   the Done transition:

   ```bash
   cap=$(curl -sS -u "$AUTH" "$ROOT/issue/$ticket?fields=customfield_11907" \
     | jq -r '(.fields.customfield_11907 // []) | map(.value) | join(",")')
   if [ -z "$cap" ]; then
     echo "REFUSING to Done $ticket — Platform Capability is empty." >&2
     echo "Set it via twg jira workitem update --field 'Platform Capability=...' (or jira-pick's step 5 if this was" >&2
     echo "picked up before that step landed). Then retry Done." >&2
     exit 1
   fi
   ```

   `jira-pick` sets the capability at claim time by default; if the
   ticket was picked up before that step existed, or someone
   claimed it outside the skill, set it now — pick from the PLAT
   allowed values in the `jiraai` cookbook (Delivery management,
   Databases, Service communication, Observability, Edge, IAM,
   Cloud compute, Application management, …, or `Not applicable`
   for edge cases).

   Then update the bead:

   ```bash
   bd note <id> "Reply posted via twg jira workitem comment create on $ticket. \
Ticket state now: <open / done / waiting-for-customer>. \
Transitioned via twg jira workitem update --status: <yes/no>."
   ```

11b. **If the answer shape is "Need more info" — transition the
    ticket to `Waiting for customer` right after the comment posts.**
    The status change is the machine-readable signal that the ball
    is in the reporter's court; support dashboards, SLA timers, and
    the 7-day automation-nag all key off it. Do NOT skip this — a
    "Need more info" comment on a ticket still marked `In Progress`
    misleads the queue.

    JSM projects (PLAT and other support-desk projects) expose a
    dedicated `Waiting for customer` transition. Discover the ID for
    THIS ticket's issue type first — do not hard-code (differs
    across issue types and can drift):

    ```bash
    WFC_TID=$(curl -sS -u "$AUTH" "$ROOT/issue/$ticket/transitions" \
      | jq -r '.transitions[]
          | select(.to.name | test("Waiting for customer"; "i"))
          | .id' | head -1)

    if [ -z "$WFC_TID" ]; then
      echo "REFUSING to transition $ticket — no 'Waiting for customer'" >&2
      echo "transition available from the current status. Available:" >&2
      curl -sS -u "$AUTH" "$ROOT/issue/$ticket/transitions" \
        | jq -r '.transitions[] | "  \(.id)\t\(.name) -> \(.to.name)"' >&2
      echo "" >&2
      echo "Non-JSM projects (GT and similar) do not have this status." >&2
      echo "Fall back to a bead note + async-wait only, and hand off" >&2
      echo "to the operator to pick a suitable status by hand." >&2
    else
      curl -sS -u "$AUTH" -X POST "$ROOT/issue/$ticket/transitions" \
        -H 'Content-Type: application/json' \
        -d "{\"transition\":{\"id\":\"$WFC_TID\"}}"
      # → HTTP 204, empty body
    fi
    ```

    Record it on the bead:

    ```bash
    bd note <id> "Transitioned $ticket to 'Waiting for customer' \
(transition id $WFC_TID) after posting Need-more-info reply."
    ```

    **Reverse on reporter reply.** The async-wait arm (step 12)
    wakes when a new non-me comment lands; that wake-prompt MUST
    re-transition the ticket OUT of `Waiting for customer` back to
    the working state (`In Progress`, transition id `31` for
    Story/Task/Bug/Sub-task/Feature — re-discover for JSM types the
    same way). Leaving a replied-to ticket stuck in
    `Waiting for customer` is the same failure mode as the initial
    skip: the queue reader is misled.

12. **If the answer shape is "Need more info" — arm async-wait for
    the reporter reply.** Reporter response time on PLAT is
    hours-to-days; do NOT leave the operator to check manually.
    Delegate to **async-wait** with a bounded re-arm loop:

    ```bash
    bd note "$close_bead" "async-wait armed: watch:jira=$ticket \
reason=awaiting-reporter-reply status=Waiting-for-customer cap=24h. \
On wake: re-read comments via jiraai-review; if a new non-me \
comment exists, transition ticket OUT of Waiting-for-customer \
(back to In Progress via twg jira workitem update --status 'In Progress') then handle the reply; \
else re-arm up to 24h total, then hand off to operator."
    ScheduleWakeup(
      delaySeconds=1800,
      reason="check for reporter reply on $ticket",
      prompt="Resume $close_bead — pull jiraai-review $ticket, \
grep comments after the timestamp in the bead note; if new \
non-me comment, first transition $ticket OUT of \
Waiting-for-customer (discover the In-Progress transition id via \
GET $ROOT/issue/$ticket/transitions; usually 31 for \
Story/Task/Bug/Sub-task/Feature — re-discover for JSM types), \
then act on the reply; else re-arm ScheduleWakeup for another \
1800s if total wait < 24h; after 24h cap, PushNotification the \
operator with a summary and stop."
    )
    ```

    Cap the total re-arm chain at 24h — after that, hand off to the
    operator (PushNotification + `blocking:human` on the bead). Do
    NOT loop forever silently. See `async-wait § Notification policy`
    for what warrants a `PushNotification` and what does not.

## Gotchas

- **Never post without explicit OK.** Jira comments are visible to
  the reporter and often external stakeholders; a bad draft posted
  autonomously is very hard to walk back.
- **Do not paste stack traces or internal URLs into the Reply**
  unless the reporter can act on them. Move that content to
  `## Context` for the human posting.
- **Do not translate.** Post in the ticket's own language (usually
  English at ManoMano). STE100 is the *style*, not the language.
- **Do not close the ticket from this skill.** That's the human's
  call after they read the reporter's follow-up.

## Composes with

- **ste100**: the writing standard the Reply obeys.
- **jira-explore / jira-fix / jira-ticket**: the pipeline this
  closes.
- **twg-jira**: `twg jira workitem comment create` — the posting mechanism (this skill is the
  ASD-STE100 close-out variant of that primitive — always route
  through it, never hand-roll `curl`). Also `twg jira workitem update --status ...` for the
  state transition after the reply lands (twg resolves per-issue-type transition IDs; see
  `jiraai` cookbook for the raw IDs).
- **jiraai** (cookbook): ADF format + auth details the posting
  step relies on.
- **jiraai-freshness-check**: mandatory pre-post gate. Method
  step 1 snapshots the ticket; the code block in step 11 diffs
  and refuses to post on `NEW_COMMENTS` / `STATUS_CHANGE`. Extend
  the same gate around the Done transition (step 11) and the
  `Waiting for customer` transition (step 11b)  -  a status flip
  to Won't Do / Duplicate between draft and Done is exactly the
  drift this catches.
- **async-wait**: for "Need more info" replies — bounded ScheduleWakeup
  loop (1800s per arm, 24h total cap) via `watch:jira=<KEY>`. On
  wake, re-checks comments; PushNotification only when actionable
  (new reporter comment OR 24h cap hit).
- **beads**: record the posted-reply state.
