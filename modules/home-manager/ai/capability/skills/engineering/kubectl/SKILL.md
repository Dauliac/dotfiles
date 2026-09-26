---
name: kubectl
description: Kubernetes CLI — inspect, describe, tail logs, exec, port-forward, apply, diff, patch, debug. Trigger on any Kubernetes task: "check the pod", "why is X CrashLoopBackOff", "tail logs from Y", "kubectl this manifest", or when the user mentions a namespace / deployment / pod / service / node. Always pair with the `explicit-cluster-context` skill — never rely on the shared current-context in `~/.kube/config`.
---

# kubectl — Kubernetes CLI

`kubectl` is the primary handle to a Kubernetes cluster. Reach for it
for anything from "is my pod alive" to "roll back this deployment".

**IMPORTANT — cluster context**: always pass `--context <ctx>` and
`-n <ns>` explicitly. Never rely on the shared current-context in
`~/.kube/config`. See the `explicit-cluster-context` skill for why.

## When to reach for it

- Inspect state: pods, deployments, services, nodes, events, ingresses.
- Debug workloads: describe, logs, exec, port-forward, debug ephemeral
  containers.
- Change state: apply, patch, rollout, scale, delete (with caution).
- Compare desired vs live: `kubectl diff -f`.

For long-lived cluster observation (multi-resource dashboards, live
event streams), prefer the `k8s-watch` skill — it opens k9s in a herdr
split scoped to the right context + namespace + selector.

## Core surface

| Category | Commands |
|---|---|
| **Read** | `get <kind> [name]`, `describe <kind> <name>`, `explain <kind>`, `top pod\|node`, `events` |
| **Debug** | `logs [-f] [--tail=N] [--previous] <pod> [-c <container>]`, `exec -it <pod> -- <cmd>`, `debug <pod>/<node>`, `port-forward <pod\|svc> local:remote`, `cp` |
| **Change** | `apply -f`, `patch <kind> <name> --type=…`, `edit <kind> <name>`, `scale --replicas=N <kind>/<name>`, `rollout {status,restart,undo} <kind>/<name>`, `delete <kind> <name>` |
| **Compare** | `diff -f`, `apply --dry-run=server -f`, `apply -f --server-side` |
| **Auth**  | `auth can-i <verb> <resource>`, `auth whoami` |
| **Meta**  | `api-resources`, `api-versions`, `config …` (read-only) |

Namespace selection: always `-n <ns>` (or `--all-namespaces` when
listing across).

## Recipes

**Triage a broken pod**:

```bash
kubectl --context <ctx> -n <ns> get pods -l app=<name>
kubectl --context <ctx> -n <ns> describe pod <pod>
kubectl --context <ctx> -n <ns> logs <pod> --tail=200
kubectl --context <ctx> -n <ns> logs <pod> --previous --tail=200  # crash loop
kubectl --context <ctx> -n <ns> events --for pod/<pod>
```

**Recent events across a namespace, newest first**:

```bash
kubectl --context <ctx> -n <ns> get events \
  --sort-by='.lastTimestamp' | tail -50
```

**Rollout status + rollback**:

```bash
kubectl --context <ctx> -n <ns> rollout status deploy/<name>
kubectl --context <ctx> -n <ns> rollout history deploy/<name>
kubectl --context <ctx> -n <ns> rollout undo deploy/<name>
```

**Diff a manifest against live before applying**:

```bash
kubectl --context <ctx> diff -f manifest.yaml
kubectl --context <ctx> apply -f manifest.yaml --dry-run=server
kubectl --context <ctx> apply -f manifest.yaml --server-side
```

**Ephemeral debug container** (image includes shell + tools):

```bash
kubectl --context <ctx> -n <ns> debug -it <pod> \
  --image=nicolaka/netshoot --target=<container>
```

**JSONPath / go-template output for scripts**:

```bash
kubectl --context <ctx> -n <ns> get pod <p> \
  -o jsonpath='{.status.containerStatuses[0].restartCount}'
```

## Gotchas

- `kubectl config use-context` mutates shared state — **never run it
  from an agent**. Use `--context <ctx>` per invocation.
- `--all-namespaces` (`-A`) on a large cluster returns thousands of
  rows — always narrow with `-l <selector>` / field selectors first.
- `delete` is not soft — it triggers finalizers and may cascade
  (`--cascade=orphan` to keep dependents). Confirm before running
  destructive ops on shared clusters.
- `logs -f` blocks — pair with **k8s-watch** or run in a herdr split
  via **herdr-run** rather than blocking your synchronous call.
- Time on `logs --since=…` uses the API server clock, not local.
- `apply` vs `apply --server-side`: SSA is required for large CRs and
  fields owned by controllers; default client-side apply silently
  drops unknown fields.
- `kubectl auth can-i <verb> <res>` before ops on unfamiliar clusters
  — silent 403s waste an hour of debugging.

## Composes with

- **explicit-cluster-context**: the always-on rule this skill assumes.
- **k8s-watch**: opens k9s scoped to `--context + -n + -l …` so the
  user watches state change live while you mutate.
- **herdr-run**: for `kubectl logs -f`, `kubectl port-forward`, or any
  long-running invocation the user should see progress on.
- **herdr-find**: before spawning a fresh `k9s` / `stern` / `logs -f`
  pane, check for an existing one scoped to the same `--context` +
  namespace + label selector; reuse it via `herdr-run --pane <id>`.
