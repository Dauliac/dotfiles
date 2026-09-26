---
name: ezsre
description: ManoMano internal SRE CLI — reporting, investigation, and mitigation across AWS, EKS, GitLab, JFrog, Kafka Connect, and Vault. Trigger on "run ezsre", "list all our EC2/ECR/lambdas/VPCs", "find unused security groups", "clean up ECR/AMIs/snapshots", "pause/resume the kafka connectors", "GitLab rollout / GPG key / project audit", "JFrog storage metrics", "Vault search-keys / search-values", or any support-ticket task that spans multiple AWS accounts / regions at once. Read-only by default; some subcommands are destructive — always classify before running.
---

# ezsre — ManoMano SRE CLI

`ezsre` is the SRE team's swiss-army CLI at ManoMano. It fans commands
out across multiple AWS accounts, EKS clusters, GitLab, JFrog, Kafka
Connect, and Vault from a single invocation, using keyed
account/role/region maps configured once under `~/.config/ezsre`.

Prefer `ezsre` over hand-rolled `aws` + `for account in …` loops when
the task is inherently multi-account (fleet reporting, cross-region
cleanup, cross-cluster ops). Use the plain `aws` skill when the task
is scoped to one account/region.

## When to reach for it

- Fleet reporting: "list every EC2 / ECR image / Lambda / VPC / EIP
  across all our accounts".
- Cleanup: unused security groups, orphaned AMIs / snapshots / ENIs,
  ECR pruning, ElastiCache cleanup.
- Kafka Connect ops: pause / resume connectors, resume-from-RDS,
  bulk pause / resume, health checks.
- GitLab ops: rollout, GPG keys, MR creation, sandbox, `search`,
  `what-have-i-done`, praefect / gitaly log SCP.
- Vault: search keys / values across environments and regions.
- JFrog: storage metrics, build / user pruning.

## Discovery first — do not guess

`ezsre`'s surface changes over time. Three read-only commands answer
"what can I do?" without side effects:

```bash
ezsre commands                        # 71-row table: command, effect, purpose
ezsre commands --json | jq .          # same, machine-readable
ezsre what-about "rotate kafka connectors in prod"   # LLM-picked shortlist
ezsre <group> --help                  # exact verbs + flags for a group
```

The **effect column** in `ezsre commands` is load-bearing:

| Effect | Meaning | Safety |
| --- | --- | --- |
| `read-only` | Prints or queries, no state changes | Safe to explore |
| `additive` | Creates / adds without deleting | Confirm with user first |
| `reconciling` | Converges live state to a desired state | Confirm — can delete drift |
| `destructive` | Deletes / mutates / can page someone | **Explicit user OK required** |

Never run a `destructive` or `reconciling` command as part of
investigation. Move to fix phase, get the user's OK, then run it.

## Command groups

```
aws       — multi-account AWS: EC2, ECR, Lambdas, VPCs, EIPs, RDS, ElastiCache
eks       — EKS ops: multi-exec across clusters, headless-svc / helm cleanup
gitlab    — GitLab admin: rollout, sandbox, GPG, MR creation, search
jfrog     — Artifactory: storage metrics, prune builds / users
kafka     — Kafka Connect: connector list / status / pause / resume / health
vault     — Vault: search-keys, search-values (across envs + regions)
config    — layered config under ~/.config/ezsre
creds     — show where each credential would be sourced from
repl      — Python REPL in ezsre context
```

Root globals (pass **before** the subcommand): `--aws-accounts`,
`--aws-key`, `--aws-regions`, `--aws-roles`, `--vault-endpoints`,
`--vault-regions`, `--vault-envs`, `--gitlab-token`, `--gitlab-uri`.
Resolution: flag > env var > `~/.config/ezsre` > built-in default.
Set the recurring ones once with `ezsre config set <key> <value>` and
inspect with `ezsre config ls`.

## Credentials

Secrets are never read from the config file. They come from env vars
or Vault. To see where a credential *would* come from without printing
its value:

```bash
ezsre creds           # list every credential + resolved source
ezsre creds --check   # actually probe Vault (auth + field presence)
```

`--check` is safe (no value ever printed) but does authenticate — run
it if a downstream command 401s.

## Recipes for support tickets

**"Find the orphan security groups"** — read-only, safe:

```bash
ezsre aws list-unused-ec2-securitygroups
ezsre aws list-ec2-sg-with-subnets-rules --aws-key=prd
```

**"Which Lambdas across all accounts are on runtime X?"**:

```bash
ezsre aws list-lambdas | jq '[.[] | select(.Runtime=="python3.9")]'
```

**"A Kafka connector is stuck"** — read state first, then mitigate
after user OK:

```bash
ezsre kafka connectors list
ezsre kafka connectors status --connector=<name>
ezsre kafka connectors check-health     # destructive/mitigating — get OK
ezsre kafka connectors pause --connector=<name>   # destructive
ezsre kafka connectors resume-connector --connector=<name>
```

**"What have I / a user done in GitLab in the last week?"** —
audit-trail for a support ticket about a rogue change:

```bash
ezsre gitlab what-have-i-done --user=<login> --since='7d'
ezsre gitlab search --query=<term>
```

**"Vault has a value somewhere but I can't find it"**:

```bash
ezsre vault search-keys  --pattern='<glob>'
ezsre vault search-values --pattern='<glob>'  # slower, exhaustive
```

**"Multi-cluster EKS one-off"**:

```bash
ezsre eks multi-exec --cmd='kubectl get pods -A | grep CrashLoopBackOff'
```

Multi-exec is `destructive` in the catalog because it runs a
user-supplied command against every cluster — read the effect column,
not the verb.

## Anti-patterns

- Don't run a `destructive` command during `jira-explore` — that phase
  is read-only. Save it for `jira-fix`, after user OK.
- Don't hand-roll cross-account loops when `ezsre` already fans out —
  keyed accounts + roles are the whole point.
- Don't set secrets in `ezsre config set` — the CLI refuses; use env
  vars or Vault. Check with `ezsre creds` first.
- Don't skip `--aws-key`/`--aws-regions` on a mutating command — the
  default is "all accounts / all regions" and that is rarely what you
  want when writing.
- Don't reach for `ezsre` when the task is single-account / single-cluster
  — plain `aws` or `kubectl` is more precise and easier to audit.
- Don't guess a subcommand exists — always `ezsre commands` or
  `ezsre what-about "…"` first.

## Composes with

- **aws**: single-account AWS work; `ezsre` for multi-account fan-out.
- **kubectl** + **explicit-cluster-context**: `ezsre eks` targets
  named clusters; scoped ops still use `kubectl --context`.
- **pup**: correlate an ezsre finding with Datadog metrics / logs.
- **glab**: `ezsre gitlab` for admin fan-out, `glab` for the ordinary
  MR / pipeline surface a developer touches.
- **jira-explore**: read-only ezsre discovery (`list-*`, `all-*`,
  `search`, `what-have-i-done`) feeds `proof.md`.
- **jira-fix**: destructive / additive ezsre commands (`clean-*`,
  `rollout`, `pause`/`resume`) belong here, after user OK.
- **beads**: capture "we ran `ezsre <cmd>` on <ticket>" so the audit
  trail survives session boundaries.
