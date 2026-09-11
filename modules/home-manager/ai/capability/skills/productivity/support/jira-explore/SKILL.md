---
name: jira-explore
description: Ticket exploration phase — collect facts, reproduce the reported behavior, and write a proof.md under the per-ticket try dir. Reads the ticket + parent chain + full comment thread + linked issues + remoteLinks via `jiraai-review`; hunts for related / duplicate tickets via `twg jira workitem query --jql "..."` (or `twg jira workitem search "text"` for fuzzy). **Consults the warm Dust conversation seeded by `jira-ticket` at every round** — Dust indexes Notion / Slack / Confluence / prior incidents and holds the ticket's growing context across sessions; feed findings back so its memory stays current. Trigger on "explore this ticket", "gather facts on X", "reproduce PLAT-1234", "investigate the ticket", or as the first phase called by the `jira-ticket` orchestrator. Read-only phase — do not design a fix here, do not draft an answer here.
---

# jira-explore — collect facts + reproducible proof

**IMPORTANT — investigation stays in the try dir, not in Jira.** The
reporter is a human waiting for a short, useful answer. Everything
you find during exploration — dead ends, hypotheses, log dumps,
"maybe X, maybe Y" — goes into `$ticket_dir/proof.md` and bead notes,
**never** into a Jira comment on the support ticket. The ticket
sees only the final answer that `jira-answer` produces after user OK.

Turn a vague Jira / support ticket into a structured `proof.md` a
future you (or a colleague, or the fixer) can rely on. **Read-only**:
no code changes, no MR opens, no destructive commands — reproduce
against dev / staging / read replicas, never against prod state you
would mutate.

## When to reach for it

- The `jira-ticket` orchestrator hands you off after setup.
- The user says "just look at this ticket, don't fix it yet".
- You need to update `proof.md` with fresh findings mid-fix.

## Inputs

- Ticket ID, URL, or full body.
- Per-ticket try dir (set up by `jira-ticket`): `$ticket_dir`.
- `$ticket_dir/ticket.md` — briefing dump produced by
  `jiraai-review` at setup. Read it first; it already has the
  header, custom fields (team, capability), parent chain, children,
  linked issues, remoteLinks (MRs), and the full comment thread.
  Never re-`curl` what is already there.
- `$ticket_dir/related.md` — **deep** dump (from `jiraai-review
  --deep`) covering the ticket's parent + subtasks + linked issues
  ONE level out. Contains a batch-fetched table of related tickets
  (KEY, rel, status, assignee, summary — cross-project OK) plus a
  list of MR URLs found on those related tickets. Read it BEFORE
  starting your own investigation — if a related ticket in another
  project already has a merged MR fixing the same root cause, you
  are about to duplicate work. Use `ci-watch` on any relevant MR
  URL instead.
- `$ticket_dir/related-mrs.txt` — deduplicated list of MR URLs
  extracted from `related.md`; `jira-ticket` uses it to spawn
  `phase:watch-related-mr` beads (opt-in via `blocking:human`).
- Per-ticket Dust conversation ID (already persisted).
- `~/.local/share/jiraai/config.yaml` — pulls `${SITE}`,
  `${USER_EMAIL}`, and the **support project** key (see
  `jira-ticket` for the `defaults.support.project` override).
- Access to the systems under investigation (glab, kubectl, pup,
  logs, dashboards).

## Output: `$ticket_dir/proof.md`

Every explore run appends (does not overwrite) to `proof.md`. Use
this shape — one block per finding, all filled in or explicitly
marked `unknown`:

```markdown
# <TICKET-ID> — Exploration Proof

## Ticket summary
<one paragraph from the reporter's own words>

## Reported symptom
<what the user says is wrong>

## Environment
- Cluster / context:
- Namespace:
- Service / component:
- Version / commit / release:
- First-seen timestamp (UTC):
- Reporter (jira user / team):

## Repro steps
1. …
2. …
3. Observe: <what happens>
   Expected: <what should happen>

## Evidence
- Kubernetes: `kubectl --context <ctx> -n <ns> …`
  (paste truncated output, link to full log dump under
  `$ticket_dir/evidence/<file>.log`)
- Datadog: `pup logs query …` / monitor URL
- GitLab: MR / pipeline / job URLs
- Git blame / commits: sha, subject line

## Reproducibility
- [ ] Reproduces locally
- [ ] Reproduces on dev / staging
- [ ] Only in prod (state-dependent — describe why)
- [ ] Cannot reproduce (describe attempts + what would be needed)

## Root cause hypothesis
<one line — best current guess; cross-linked to the evidence above>
<alternative hypotheses if the first turns out wrong>

## Impact
- Blast radius: <users / requests / regions / severity>
- Workaround for the reporter (if any):

## Open questions
- <thing you tried and couldn't answer>
- <thing you'd need the user / owner team to answer>
```

Put large log dumps under `$ticket_dir/evidence/` and link them
from `proof.md` — keep the doc itself scannable.

## Method

1. **Read `ticket.md` verbatim** — it's the `jiraai-review` dump;
   do not summarize away the reporter's exact wording; ambiguity
   there is signal. If it's stale (setup ran hours ago on a hot
   ticket), refresh with `jiraai-review "$ticket" > ticket.md`.
2. **Widen the context — read `related.md` FIRST**, then search
   with `twg jira workitem query --jql`.

   - **`related.md` (from `jiraai-review --deep` at setup)** —
     parent + subtasks + linked issues, ONE level out. Every row
     is a ticket you should not ignore: a parent Feature may
     define scope; a subtask may already be a repro; a `Blocks`
     link may point at the ticket that ACTUALLY needs to move
     first; a linked ticket in another project may already have
     an MR that fixes the root cause.

   - **MR URLs from `related-mrs.txt`** — if any URL points at a
     merged MR touching the same code path, STOP and check whether
     your fix is already landed. If it points at an open MR,
     consider opening `ci-watch` on it instead of racing.

   - **`twg jira workitem query --jql` — broader search** for same component / same
     error signature / same reporter, when `related.md` didn't
     find the obvious neighbours.

   ```bash
   # e.g. same component + open in the last 30 days
   twg jira workitem query --jql "project = $JIRAAI_PROJECT AND component = <name> \
     AND resolution = Unresolved AND created >= -30d" --limit 50
   ```

3. **Ask the warm Dust conversation for background — MANDATORY,
   never skip.** Dust indexes Notion, Slack, Confluence, GitHub, and
   past incidents; you can't. `jira-ticket` already seeded it with
   the ticket header and comment thread — build on that context with
   an open question. Log via the `dust_ask` helper defined in
   `jira-ticket` so `dust-log.md` stays complete.

   ```bash
   dust_ask "For $ticket, I'm investigating <component>. Given the \
ticket you already have: (a) any prior incidents with the same \
signature? (b) any recent deploys / config changes / migrations \
touching <component> in the last <window>? (c) any known-good \
Notion / Confluence page or ADR the owner team already wrote about \
this? Return links, ticket keys, or say 'nothing indexed'."
   ```

   Also mandatory: **feed each significant local finding back to Dust
   in the same conversation**, so subsequent phases inherit a warm,
   accurate context. Don't wait for a big writeup — small updates
   keep Dust useful:

   ```bash
   dust_ask "Update: I reproduced $ticket on staging with <steps>. \
Log line is <one line>. Root-cause hypothesis: <one line>. Anything \
in your indexed sources that contradicts or supports this?"
   ```

4. **Reproduce** — steps 1–N in `proof.md`. Prefer:
   - `kubectl … describe / logs / events` for k8s (with
     `explicit-cluster-context`).
   - `pup logs query --from='<recent>' --query='…'` for logs at scale.
   - `pup monitors get <id>` for monitor definitions.
   - `glab mr view` / `glab ci view` for MR / pipeline context.
   - `aws --profile <p> --region <r> … describe-*/list-*/get-*` for
     single-account AWS resource state (never omit `--profile` /
     `--region`).
   - `ezsre commands` → any `read-only` row (`all-*`, `list-*`,
     `search`, `what-have-i-done`) for multi-account / cross-cluster
     / fleet-wide facts. Ask `ezsre what-about "…"` if unsure.
   - `git log --since=<first-seen>` in the relevant worktree for
     what changed near the incident.
5. **Correlate** — a single fact rarely proves cause. Pair a metric
   spike with a log burst with a deploy commit with a config change.
6. **Write proof.md incrementally** — commit your evidence as you
   find it, don't wait for a final version.
7. **Update the bead**:

   ```bash
   bd note <id> "Explore round N: hypothesis is <one line>. \
Proof at $ticket_dir/proof.md. Blocked on <if anything>."
   ```

## Fact-gathering shortcuts

| To get… | Try… |
|---|---|
| Recent pod restarts | `kubectl --context <ctx> -n <ns> get pods --sort-by='.status.containerStatuses[0].restartCount' \| tail` |
| Crash logs for the previous instance | `kubectl … logs <pod> --previous --tail=500` |
| Recent events in a namespace | `kubectl … events --sort-by='.lastTimestamp' \| tail -50` |
| Recent deploys of a service | `glab ci list --repo <group/project> --status=success \| head` |
| Recent MRs touching a file | `glab api "projects/<enc>/merge_requests?state=merged&per_page=20" \| jq '.[] \| select(.changes_count>0)'` |
| Log spike shape | `pup logs aggregate --compute=count --query='<q>' --from='<window>' --group-by=<facet>` |
| Monitor state at the time of the incident | `pup monitors get <id>` + `pup monitors search` |
| Multi-account AWS fleet snapshot | `ezsre commands` → pick `all-*` / `list-*` (all `read-only`) |
| "Which SRE command does what I want?" | `ezsre what-about "<plain-language intent>"` |
| Single-account AWS resource state | `aws --profile <p> --region <r> <svc> describe-*/list-*/get-*` |
| Confirm which AWS account / role a call lands on | `aws --profile <p> --region <r> sts get-caller-identity` |
| CloudWatch Logs for a Lambda / service | `aws --profile <p> --region <r> logs filter-log-events --log-group-name <g> --start-time <ms>` |
| Cross-account GitLab / Kafka Connect / Vault audit trail | `ezsre gitlab {search,what-have-i-done}`, `ezsre kafka connectors {list,status}`, `ezsre vault search-{keys,values}` |

## Gotchas

- **Read-only means read-only.** No `apply`, no `patch`, no `mr
  create`, no `bd close` — that's the fix / answer / wrap-up phase.
- **Prod safety:** `kubectl exec`, `port-forward`, and `debug` can
  touch prod state. Prefer read-only alternatives (`logs`,
  `describe`, `events`, `top`) unless the user explicitly OKs prod
  interaction.
- **Log volume:** aggregate before you query. `pup logs aggregate
  --compute=count` first, drill down second.
- **Time zones:** Datadog / k8s events / GitLab all use UTC; ticket
  bodies often don't — normalize timestamps in `proof.md`.
- **Confidence markers:** in `proof.md` write "hypothesis" not
  "cause" until repro is green. Overconfident proofs mislead the
  fix phase.

## Composes with

- **jira-ticket** (parent orchestrator).
- **jira-fix** (next phase — takes `proof.md` as input).
- **jiraai-review** (input: `ticket.md` at setup, refresh on hot
  tickets).
- **twg-jira** (`twg jira workitem query --jql "..."` — find related / duplicate tickets, walk the
  initiative tree).
- **jiraai** (cookbook — auth, ADF, custom-field IDs — read once,
  never re-derive).
- **dust / glab / kubectl / pup / try**: the fact-gathering tools.
- **ezsre**: multi-account SRE fan-out (AWS / EKS / GitLab / Kafka
  Connect / Vault / JFrog) — only the `read-only` rows in `ezsre
  commands` in this phase.
- **aws**: single-account AWS CLI — read-only `describe-*/list-*/
  get-*/filter-log-events/sts get-caller-identity` in this phase,
  always with explicit `--profile` + `--region`.
- **explicit-cluster-context**: mandatory for every `kubectl` call.
- **beads**: cross-session memory of the exploration state.
- **herdr-find**: on resume, locate the ticket's workspace / pane by
  label so investigation continues in the same tab, not a fresh split.
