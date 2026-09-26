---
name: explicit-cluster-context
description: Always pass the target cluster explicitly (`kubectl --context`, `helm --kube-context`, `k9s --context`, `stern --context`, `flux --context`, `velero --kubecontext`, `talosctl --context`) and the target namespace with `-n`, instead of relying on the current-context in `~/.kube/config`. Kubeconfig current-context and current namespace are process-shared mutable state — when multiple Claude sessions (or humans) run against different clusters concurrently, `kubectl config use-context` / `kubens` mutations race and land ops on the wrong cluster. Never run `kubectl config use-context`, `kubectx`, or `kubens` from an agent — use the per-invocation flags instead. Reach for this skill before any kubectl/helm/argocd/flux/k9s/stern command, especially when the session might be one of several touching Kubernetes.
---

# explicit-cluster-context — never rely on current-context

Kubeconfig `current-context` and the per-context `namespace:` are *shared
mutable state* on disk. Two things race against you:

- Other Claude sessions (multi-agent, multi-repo) that call
  `kubectl config use-context` or `kubens`.
- The user, who may be flipping `kubectx` in another terminal.

If you rely on the "current" context, a concurrent switch between
`kubectl get pods` and `kubectl delete pod` lands the delete on the wrong
cluster. The blast radius is unbounded — prod pods, prod secrets, prod
CRDs.

## The rule

**Every cluster-scoped invocation names its target explicitly.** No
implicit current-context, no implicit current-namespace.

**Never run** these from an agent:

- `kubectl config use-context …`
- `kubectl config set-context --current …`
- `kubectx …` / `kubens …`
- `gcloud container clusters get-credentials …` (rewrites current-context)
- `aws eks update-kubeconfig …` **without** `--alias` + then keep using
  `--context <alias>` explicitly on every follow-up command

If you truly need to add credentials, do it with `--kubeconfig` pointed
at a scratch file, not the user's shared `~/.kube/config`.

## Per-tool flags

Pick the target once at the top of your work, then thread it through every
command in the session:

```bash
CTX=prod-eu-1        # kubectl config get-contexts to list
NS=payments
```

| Tool | Explicit-target flag |
| --- | --- |
| `kubectl` | `--context "$CTX" -n "$NS"` |
| `helm` | `--kube-context "$CTX" -n "$NS"` |
| `k9s` | `--context "$CTX" --namespace "$NS"` |
| `stern` | `--context "$CTX" -n "$NS"` |
| `kubectl-cnpg` / other kubectl plugins | `--context "$CTX" -n "$NS"` (plugins inherit kubectl flags) |
| `flux` | `--context "$CTX" -n "$NS"` |
| `argocd` | `--server <argocd-server>` — argocd's own model, one server per cluster |
| `velero` | `--kubecontext "$CTX" -n "$NS"` |
| `talosctl` | `--context "$CTX"` (Talos context, distinct from k8s context) |
| `kustomize build \| kubectl apply` | put the flags on the `kubectl` side |
| `helmfile` | `--kube-context "$CTX"` (or set in `helmfile.yaml`) |

## Verifying context before mutating ops

Before any *write* (`apply`, `delete`, `scale`, `rollout restart`, helm
`upgrade`/`uninstall`), print the resolved target so the pane shows what
you're about to hit:

```bash
kubectl --context "$CTX" -n "$NS" config view --minify \
  -o 'jsonpath={.contexts[0].context.cluster}'
echo
kubectl --context "$CTX" version -o json | jq -r '.serverVersion.gitVersion'
```

If the context name doesn't exist (`error: context "$CTX" does not
exist`), stop. Do not fall back to current-context — that's exactly the
race this skill exists to prevent.

## Isolating from the shared kubeconfig entirely

For long-running work or CI-like batches, take one more step and point at
a scratch kubeconfig so nothing you (or a concurrent session) does can
mutate the user's file:

```bash
export KUBECONFIG=$(mktemp -t kubeconfig.XXXX)
kubectl config set-cluster …    # scoped to the temp file
kubectl config set-context work --cluster=… --user=… --namespace="$NS"
kubectl --context work …        # still pass --context explicitly
```

Clean up the temp file at end of session.

## Cloud-CLI credential fetchers

`aws eks update-kubeconfig` and `gcloud container clusters
get-credentials` both **rewrite** `~/.kube/config` and set current-context
as a side effect. If you must run them:

- Pass `--kubeconfig "$KUBECONFIG"` where `KUBECONFIG` is a temp file, OR
- Pass `--alias <specific-name>` and thereafter use `--context <alias>`
  on every command; never trust that current-context stayed put.

## Interaction with k8s-watch / herdr splits

The [k8s-watch](../k8s-watch/SKILL.md) skill already threads `--context`
into the `k9s` invocation — this skill is the general rule it's an
instance of. When you spawn a k9s pane and then run `kubectl` in chat, use
**the same `CTX` value** in both places, sourced from an explicit variable,
not from `kubectl config current-context` (which could have drifted
between the two calls).
