---
name: mise-deps
description: When a repo needs specific runtime/tool versions (node, python, go, terraform, kubectl, opentofu, jq, uv, pnpm, ...) to build or run, pin them in a mise config (`.mise.toml` / `mise.toml`) at the repo root instead of leaving version drift implicit. Triggers when the user says "I need node 20", "install terraform", "we need go 1.22 here", "pin the toolchain", "set up mise", "add a dep", "reproduce this env", "why is my python wrong", or when a command fails because a tool is missing or on the wrong major. Scope is the *toolchain*, not project language packages — `package.json` / `pyproject.toml` / `Cargo.toml` still own those.
---

# mise-deps — pin runtime tools in a mise config

Version drift (wrong node, wrong terraform, missing kubectl) is the
number-one "works on my machine" bug. `mise` (https://mise.jdx.dev) is
this stack's chosen way to pin those tools per-repo: one `.mise.toml`
at the repo root declares the exact versions, `mise install` reproduces
them, and `mise activate` puts them on PATH on `cd`.

This skill is a reflex: **when you need a tool to build/run this repo,
declare it in mise before running anything else.** Don't `apt install`,
don't `curl | sh`, don't rely on whatever `node` happens to be on PATH.

## What belongs in mise vs elsewhere

| Belongs in mise | Does NOT belong |
|---|---|
| Language runtimes (node, python, go, ruby, java, rust) | npm/pip/cargo packages — those live in the language's own manifest |
| CLI toolchain (terraform, opentofu, kubectl, helm, argocd, awscli, gcloud, glab, gh) | System libraries (openssl, libpq) — those are a devShell / nix concern |
| Task-adjacent tools the repo assumes (jq, yq, just, task, pnpm, uv, bun, direnv) | One-off tools you use once and never again |
| Env vars the toolchain needs (`AWS_REGION`, `KUBECONFIG`, `TF_VAR_*`) | Secrets — those go in a `.env` (gitignored) or a secret manager |

If the repo already has a `flake.nix` devShell owning the toolchain,
**do not fight it** — extend the devShell instead. Mise and devShells
solve the same problem; pick one per repo and stick with it.

## The reflex — decision in three steps

### 1. Detect

Before adding a tool anywhere else, check what the repo already uses:

```bash
ls -la .mise.toml mise.toml .tool-versions .rtx.toml 2>/dev/null
```

- `.mise.toml` / `mise.toml` present → **extend it**.
- `.tool-versions` (asdf-style) present → mise reads it natively;
  either extend it in place or migrate to `.mise.toml` if the user
  asked to consolidate.
- `flake.nix` with a `devShell` → **stop**, add the tool to the
  devShell's `buildInputs` and mention to the user you skipped mise.
- Nothing present → **propose** creating `.mise.toml` before making it.
  Ask once if the user hasn't already committed to mise.

### 2. Declare

Minimal `.mise.toml` shape:

```toml
[tools]
node       = "20.11.1"      # exact when reproducibility matters
python     = "3.12"         # major.minor OK when the repo is loose
terraform  = "1.7.5"
kubectl    = "1.29.2"
jq         = "1.7.1"

[env]
# only if the toolchain itself needs it — not app secrets
AWS_REGION  = "eu-west-1"
KUBECONFIG  = "{{config_root}}/.kube/config"
```

Rules:

- **Pin exact versions for infra tools** (terraform, opentofu, kubectl,
  helm) — a minor bump can rewrite state or change API versions.
- **Pin major.minor for language runtimes** unless the repo has a
  hard reason to freeze the patch (e.g. a native module compiled
  against a specific ABI).
- **Do not pin `latest`** — that defeats the point.
- **Group related tools together** with a blank-line separator, not
  section headers — `[tools]` is one block.
- **Env vars only for the toolchain** — `AWS_PROFILE`, `TF_VAR_*`,
  `KUBECONFIG`. Never secrets, never app config that the app already
  reads from `.env`.

### 3. Install & verify

Right after writing the file:

```bash
mise install                      # fetches/pins every declared version
mise current                      # print what will be used in this cwd
```

If `mise install` fails, read the error verbatim — usually a plugin
that needs a build dep on the host. Do not silently fall back to
`apt install`; either fix the plugin or note the gap to the user.

## When "we need a dep" is not a mise dep

Cases where reaching for mise is wrong and you should redirect:

- **Language-level package** (npm, pip, cargo, go get) → use the
  project's own manifest. `npm i foo`, `uv add foo`, `cargo add foo`.
- **System library** (`libpq`, `openssl-dev`, GPU driver) → this is a
  host / devShell concern. On a nix repo, add to `flake.nix`; on a
  non-nix repo, document in README and stop.
- **Ephemeral tool** used once (`hyperfine` for a one-off benchmark) →
  run it via `nix run nixpkgs#hyperfine` or `mise x hyperfine -- …`,
  don't add it to the pinned toolchain.
- **CI-only tool** that no developer runs locally → put it in the CI
  config's setup step, not in the repo's `.mise.toml`.

## Coexistence with other files

- **`.tool-versions`**: mise reads it. Fine to keep as-is if the repo
  is asdf-shared; only migrate to `.mise.toml` when the user wants
  mise-specific features (env, tasks, `[settings]`).
- **`Taskfile.yml` / `Justfile` / `Makefile`**: keep tasks there,
  keep tool versions in mise. Do **not** move task definitions into
  `[tasks.*]` blocks unless the user explicitly asked to consolidate on
  mise — that's a runner change, not a dep change. (Task runner choices
  are the `repo-tasks` skill's job.)
- **`.envrc` / direnv**: `direnv` + `mise activate` compose fine; just
  make sure the user isn't accidentally shadowing mise's PATH.

## Composes with

- **repo-tasks**: mise pins the *tools*, the task runner pins the
  *commands*. Both can live in the same repo. Reach for `repo-tasks`
  once the tool is available and the invocation deserves a permanent
  home.
- **herdr-run**: run `mise install` in a visible pane on first setup so
  the user watches downloads land.
- **beads**: if pinning surfaces a broader "we haven't decided on our
  toolchain" question, `bd create` a chore for the discussion rather
  than picking versions unilaterally.
