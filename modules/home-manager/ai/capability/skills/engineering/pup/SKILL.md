---
name: pup
description: Datadog API CLI — query metrics, logs, monitors, traces, incidents, dashboards, SLOs, notebooks, RUM, security, synthetics, and 30+ other Datadog domains from the terminal. Trigger on any Datadog task: "check the monitor", "read the logs", "what's the metric value", "why did this alert fire", "list traces for X", or a `datadoghq.eu` / `datadoghq.com` URL. Not the HTML parser `pup` — this is the ManoMano Datadog CLI.
---

# pup — Datadog API CLI

`pup` is a Datadog API CLI covering metrics, logs, monitors, traces,
dashboards, SLOs, incidents, and more. It authenticates via OAuth2 or
an API key + app key pair, and returns JSON by default.

**Not to be confused with** the HTML-parsing tool of the same name —
this one is Datadog-only.

## When to reach for it

- Investigating a Datadog alert or monitor from a Jira / support
  ticket.
- Pulling recent logs, metrics, or traces to correlate with an incident.
- Reading dashboard state or SLO burn.
- Any Datadog task where the alternative is opening the web UI and
  copy-pasting.

## Auth + env

| Method | Setup |
|---|---|
| OAuth | `pup auth login` (interactive) |
| Headless | `DD_API_KEY` + `DD_APP_KEY` + `DD_SITE` env vars |
| Multi-org | `pup auth login --org <name>` then `pup --org <name> …` |

## Global flags to know

| Flag | When to use |
|---|---|
| `--org <name>`      | Multi-org — pick the session |
| `--output <fmt>`    | `json` (default), `table`, `yaml`, `csv` |
| `--agent`/`--no-agent` | Wrap / un-wrap the `{status,data,metadata}` envelope |
| `--yes`             | Skip confirmations (auto-approve) |

**Envelope quirk** (matters for scripting): `pup` auto-detects AI
coding assistants and wraps JSON responses in a `{status, data,
metadata}` envelope. Run interactively you see the envelope; the
user running the same command in their shell sees the raw payload.

- Scripts you save for the user or CI to run: **append `--no-agent`**
  so the output matches what they'll see (`pup --no-agent monitors
  list --tag='env:prod' | jq '.[].name'`).
- Live investigation for yourself: leave defaults — the envelope
  status field is useful.

## Common domains

Each domain has its own subcommand group with `list`, `get`, and
domain-specific verbs. Sample:

- `pup monitors {list,get,mute,unmute}`
- `pup logs {aggregate,query,tail}` — prefer `aggregate --compute=count`
  over fetching raw logs to count them
- `pup metrics query` — always specify an aggregation
- `pup traces {list,get}`
- `pup dashboards {list,get}`
- `pup slos {list,get,status}`
- `pup incidents {list,get}`
- `pup rum {list,get}`
- `pup synthetics {list,get}`
- `pup notebooks {list,get}`

Run `pup <domain> --help` for the exact verbs.

## Recipes

**Recent logs for a service** — aggregate first, then narrow:

```bash
pup logs aggregate --compute=count \
  --query='service:my-svc status:error' \
  --from='1h' --group-by='@http.status_code'

pup logs query \
  --query='service:my-svc status:error' \
  --from='1h' --limit=50
```

**Metric value over a window** (nanoseconds for APM durations!):

```bash
pup metrics query \
  --query='avg:trace.http.request.duration{service:my-svc}' \
  --from='1h'
```

**Why did this monitor fire?**:

```bash
pup monitors get <monitor-id>
pup monitors search --query='<name>'
```

## Anti-patterns (encoded in the CLI itself)

- Don't omit `--from` on time-series queries — unexpected ranges or
  errors.
- Don't `--limit=1000` on a first pass — start small, refine.
- Don't list all monitors / logs without filters in large orgs.
- APM durations are **nanoseconds**, not seconds or ms.
- Don't fetch raw logs to count them — `logs aggregate --compute=count`.
- Don't use `--from=30d` unless you actually need a month.
- Don't retry blindly on failure — 401 means re-auth, 403 means
  missing permissions.
- Don't run `metrics query` without an aggregation (avg / sum / max /
  min / count).
- Don't pipe huge JSON through many `jq` transforms — filter at the
  API level.
- When authoring scripts for the user or CI, always add `--no-agent`.

## Composes with

- **jira-explore**: pull the relevant monitor / logs / metrics for a
  Datadog-flagged ticket into `proof.md`.
- **explicit-cluster-context**: pup + kubectl in tandem when a
  Datadog alert points at a K8s workload.
