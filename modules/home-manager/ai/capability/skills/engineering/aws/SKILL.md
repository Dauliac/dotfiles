---
name: aws
description: AWS CLI v2 — inspect and mutate any AWS resource (S3, EC2, IAM, Lambda, RDS, CloudWatch Logs, EKS, ECR, Secrets Manager, STS, SSM, …). Trigger on any AWS task: "list S3 objects", "check the IAM role", "tail CloudWatch logs for lambda X", "describe the EC2 instance", "get the RDS endpoint", "assume role Y", "read a secret from Secrets Manager", or an `s3://` / `arn:aws:` URL. Always pass `--profile` and `--region` explicitly — never rely on the shared default profile / region in `~/.aws/`. For multi-account fan-out prefer the `ezsre` skill.
---

# aws — AWS CLI v2

`aws` is the primary handle to a single AWS account + region. Reach
for it for scoped inspection ("what does this bucket contain?") and
scoped mutation ("upload this object", "restart this task").

**IMPORTANT — profile + region are shared state**: the current
`AWS_PROFILE` / `AWS_REGION` env vars and `~/.aws/config` default
profile are mutable, process-wide, and often stale. Always pass
`--profile <name>` and `--region <r>` explicitly, so a parallel Claude
session or a `aws configure set` from another shell cannot land your
call on the wrong account. This mirrors the `explicit-cluster-context`
skill's rule for `kubectl`.

For multi-account / multi-region fan-out ("across every account we
have"), stop and use the `ezsre` skill instead — it already fans out
with keyed accounts + roles + regions.

## When to reach for it

- Read state: `s3 ls`, `ec2 describe-*`, `iam get-*`, `logs
  filter-log-events`, `sts get-caller-identity`.
- Mutate state (scoped): `s3 cp/sync`, `ec2 start/stop`, `lambda
  invoke`, `ecs update-service`, `logs create-log-group`.
- Correlate with a Datadog alert or ticket: check the resource
  exists, its tags, its recent activity.
- Read a secret: `secretsmanager get-secret-value`, `ssm
  get-parameter --with-decryption`.
- Assume a role: `sts assume-role` (prefer `--profile` with a
  configured `role_arn` when possible).

## Auth surface at ManoMano

| Method | When to use |
| --- | --- |
| SSO profile | Day-to-day human ops — `aws sso login --profile <name>` |
| Instance / pod role | On EC2 / EKS — no explicit auth, `sts get-caller-identity` to confirm |
| Assumed role | Cross-account — configure a `source_profile` + `role_arn` profile, use `--profile <that>` |
| Static keys | Avoid — only for CI when nothing else works |

Always confirm identity before mutating:

```bash
aws --profile <p> --region <r> sts get-caller-identity
```

Silent-403s in the middle of a fix are almost always an assumed-role
that expired or the wrong profile.

## Global flags to know

| Flag | Why |
| --- | --- |
| `--profile <name>` | **Always pass explicitly** — never rely on default |
| `--region <r>` | **Always pass explicitly** — services are region-scoped |
| `--output json\|table\|text\|yaml` | `json` for scripts (pipe to `jq`), `table` for humans |
| `--query '<JMESPath>'` | Filter server output before it hits your pipe |
| `--no-cli-pager` | Don't invoke the pager (safe in scripts / captured output) |
| `--dry-run` | On supported services (EC2, IAM) — validate without mutating |
| `--no-sign-request` | Public buckets / STS — rarely needed |

## Recipes

**Confirm identity + list a bucket**:

```bash
aws --profile prod --region eu-west-1 sts get-caller-identity
aws --profile prod --region eu-west-1 s3 ls s3://<bucket>/<prefix>/
```

**Copy an object to / from S3** — always double-check the destination:

```bash
aws --profile prod --region eu-west-1 s3 cp s3://<bucket>/<key> ./local
aws --profile prod --region eu-west-1 s3 cp ./local s3://<bucket>/<key>
aws --profile prod --region eu-west-1 s3 sync ./dir s3://<bucket>/<prefix>/ --dryrun
```

Use `--dryrun` on every `s3 sync` first — a wrong `--delete` can
nuke a prefix.

**Filter CloudWatch Logs for a Lambda around an incident**:

```bash
aws --profile prod --region eu-west-1 logs filter-log-events \
  --log-group-name '/aws/lambda/<fn>' \
  --start-time $(date -d '30 min ago' +%s000) \
  --filter-pattern 'ERROR'
```

Times are **milliseconds since epoch**, UTC. A CI-only failure often
comes from a missing timezone on the query.

**Describe an EC2 instance by tag** (no wildcard scans, filter server-side):

```bash
aws --profile prod --region eu-west-1 ec2 describe-instances \
  --filters 'Name=tag:Name,Values=<name>' 'Name=instance-state-name,Values=running' \
  --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**Read a secret** — never `echo` the value into a log:

```bash
aws --profile prod --region eu-west-1 secretsmanager get-secret-value \
  --secret-id <name> --query SecretString --output text | jq .
```

**Assume a cross-account role** (prefer profile-based):

```bash
# One-off:
eval "$(aws --profile <base> sts assume-role \
  --role-arn arn:aws:iam::<acct>:role/<role> \
  --role-session-name claude-$(date +%s) \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text | awk '{print \
   \"export AWS_ACCESS_KEY_ID=\"$1\"; \
    export AWS_SECRET_ACCESS_KEY=\"$2\"; \
    export AWS_SESSION_TOKEN=\"$3}')"
```

Better: put `role_arn` + `source_profile` in `~/.aws/config` and use
`--profile <that>` — the CLI refreshes credentials automatically.

**Kick EKS auth into a temp kubeconfig** (scoped, no shared state):

```bash
KUBECONFIG=./kubeconfig aws --profile prod --region eu-west-1 \
  eks update-kubeconfig --name <cluster> --alias <ctx-alias>
KUBECONFIG=./kubeconfig kubectl --context <ctx-alias> get nodes
```

Never overwrite the default `~/.kube/config` from within a support
session — see the `explicit-cluster-context` skill.

## Output shaping

- `--query '<JMESPath>'` filters server-side before the JSON hits
  your pipe — much cheaper than `| jq '…'` on a 10MB `describe-*`.
- `--output table` for humans, `--output json` for `jq`, `--output
  text` for shell `read` / `awk` pipelines.
- Paginated APIs need `--max-items` / `--starting-token`, or a
  `--no-paginate` on small results. The default pages until the end,
  which can be slow.

## Anti-patterns

- **Never omit `--profile` or `--region`** — the account/region on
  which your call actually lands is then a race with any other shell
  or session that touched `AWS_PROFILE` / `~/.aws/config`.
- **Don't run destructive commands (`s3 rm`, `s3 sync --delete`,
  `ec2 terminate-instances`, `iam delete-*`, `rds delete-db-instance`)
  during `jira-explore`** — that phase is read-only. Move to
  `jira-fix` and get user OK first.
- **Don't `configure set` in an agent session** — it mutates
  `~/.aws/config` for every other shell on the machine.
- **Don't paginate the full log stream** — use `filter-log-events` with
  a `--start-time` and a `--filter-pattern`.
- **Don't fan out with `for account in …` loops** — that's what the
  `ezsre` skill is for.
- **Don't `echo` a Secrets Manager value into a log or a bead note**
  — pipe to `jq` for structural checks, never persist the value.
- **Don't cross-account without an explicit assume-role trail** —
  every mutation should have a `sts get-caller-identity` right before
  it in the same shell / bead note.

## Composes with

- **ezsre**: multi-account fan-out — reach for `ezsre aws …` when the
  question spans accounts / regions.
- **explicit-cluster-context**: same discipline for `kubectl`. If a
  fix touches both AWS and EKS, use both skills.
- **kubectl**: `aws eks update-kubeconfig` bridges to `kubectl`, but
  scope with a per-ticket `KUBECONFIG=./kubeconfig`.
- **pup**: pair AWS resource state with Datadog metrics / monitors /
  logs on the same window.
- **jira-explore**: read-only `describe-*`, `list-*`, `get-*`,
  `filter-log-events`, `sts get-caller-identity` feed `proof.md`.
- **jira-fix**: mutating commands belong here, after user OK.
- **s3-watch**: for a support ticket touching a specific bucket +
  prefix, open `stu` in a herdr split scoped to it.
- **beads**: capture the exact profile + region + command so future
  sessions can reproduce.
