---
name: k8s-watch
description: Whenever work touches a Kubernetes cluster (kubectl apply, helm install/upgrade, argo sync, a Job/CronJob you just kicked off), open `k9s` in a herdr split scoped to the right context + namespace + label selector so the user sees exactly the resources in play. Auto-closes on idle. Reach for it after any mutating kubectl/helm command.
---

# k8s-watch — scoped k9s TUI for the resources you just touched

The point: don't send the user to a full-cluster k9s view when you just
poked one namespace. Filter aggressively.

## Gathering context (before spawning)

You need three things:

1. **Context**: `kubectl config current-context` — or whatever context you
   just used explicitly.
2. **Namespace**: from the manifest / helm release / the `-n` flag on the
   command you just ran.
3. **Resource focus**: pods, deployments, jobs, whatever changed. If you
   just applied a manifest, grep it for `kind:` + `metadata.name` /
   `metadata.labels`.

If a label selector exists (`app=foo`, `release=bar`), that's the best filter
because k9s honors it via `--filter`.

## Single-TUI invocation

```bash
CTX=$(kubectl config current-context)
NS=api
LABEL="app=payments"

herdr-tui launch \
  --label "k9s:$CTX/$NS" \
  --auto-close-on-idle 90 \
  -- k9s --context "$CTX" --namespace "$NS" --command "pods" --headless=false
```

If you have a label selector, k9s reads a filter via its `/label=value`
key after launch — but you can pre-seed it with `--filter` in newer k9s:

```bash
herdr-tui launch \
  --label "k9s:$NS/$LABEL" \
  -- k9s --context "$CTX" --namespace "$NS" --command "pods" --filter "$LABEL"
```

## When the operation has a clear terminal state

For Jobs / helm rollouts you can use `--auto-close-when` so k9s closes as
soon as the resource is healthy:

```bash
herdr-tui launch \
  --label "k9s-job:$NS/$JOB" \
  --auto-close-when "kubectl -n $NS get job $JOB -o jsonpath='{.status.succeeded}' 2>/dev/null | grep -q '^1$'" \
  --auto-close-timeout 1800 \
  -- k9s --context "$CTX" --namespace "$NS" --command "jobs" --filter "$JOB"
```

## Failure mode

If `kubectl config current-context` errors or the namespace doesn't exist,
don't spawn the pane — the k9s TUI is useless without a valid target.
Report the error to the user in chat instead.
