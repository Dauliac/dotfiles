# Dotfiles Constitution

Governing principles for this repository. These are load-bearing —
every change in `spec/` and `plan/` must be checked against them.

## 1. Declarative or bust

Every runtime piece of state on a host must be reproducible from git.
Configuration files, service enablement, secrets bindings, and package
sets flow through Nix (flake-parts + import-tree "dendritic" modules).
Ad-hoc side effects (`sudo systemctl edit`, mutable `~/.config` files,
hand-installed packages) are forbidden — if the sandbox drifts, roll
back and re-express the change as Nix.

## 2. One flake, many modules, explicit imports

- `import-tree` auto-imports every `.nix` under `./modules/**`, but a
  module only takes effect when it's imported by a host or user config.
- Files must be **git-staged** to be visible to the flake. Unstaged
  files silently vanish.
- Feature toggles live in one place per host — `systemConstants.<host>.featureFlags`.
  Never scatter `enable = true;` across leaf files without a flag.

## 3. Secrets never touch the store — and this repo is public

`Dauliac/dotfiles` is a **public GitHub repository**. Anything committed
to git is world-readable forever (rewrites via `git filter-repo`
cannot recall clones or GitHub's forks/pull-request cache). Therefore:

- Every secret — API keys, admin passwords, WireGuard `PrivateKey`,
  `hashedPassword`, ACME provider tokens, Cloudflare tunnel
  credentials, Tailscale auth keys, MQTT passwords, TMDB keys — is
  delivered through **SOPS** (`sops-nix`), referenced by module code
  via `config.sops.secrets.<name>.path` (never the literal).
- The **encrypted** SOPS files (`*.enc.yaml`, `*.enc.json`) are the
  only secret-bearing artifacts allowed in git. They decrypt only for
  age-recipient keys held by the deployment target (gary's host key
  + user private keys, never in the repo).
- Even in comments, in commit messages, and in `spec/plan/memory/`
  docs — never inline a secret value or a value that would leak the
  shape of one (e.g., "the token starts with `CFP_`" is a leak).
- Semi-sensitive constants (tunnel UUIDs, tailnet names,
  device serial IDs) are conservatively routed through SOPS too —
  defense in depth. If a value would embarrass the user if grepped
  from the repo, it's SOPS.
- Public-facing constants (LAN IPs — RFC1918, hardware model names,
  domain names already published in DNS, ACME notification email) are
  the only free-in-source values.

The test: `git grep -E '^\s*[a-zA-Z_]+\s*=\s*"[^"]{20,}"'` should
return only public URLs, package refs, and short strings. Long
opaque values in the source are red flags.

## 4. Stylix is the single source of truth for theme

Fonts, palette, and opacity ride on `stylix`. `catppuccin/nix` remains
alongside for programs stylix can't target, but conflicting targets
must be disabled explicitly (see `theme.nix`). Nixvim opts out via
`stylix.targets.nixvim.enable = false` because it manages its own
transparency in Lua.

## 5. Host budget: keep gary sober

Gary is a home server on modest hardware. New services must:

- fit inside a **feature flag** so they can be disabled per-boot
- be reachable through the existing nginx reverse-proxy (subdomain on
  `gary.local` in LAN mode, `j4rd1.cloud` when ACME is on)
- **not** run privileged network stacks (VPN kill-switch is
  namespaced, not host-wide)
- surface at least one health signal (systemd status, Home Assistant
  sensor, or a Prometheus scrape)

## 6. Fail loudly, roll back cleanly

Prefer `lib.mkForce` and assertions over silent overrides. Every deploy
must be reversible with `xi rollback` (or the VM/system-manager
equivalent). If a change requires a manual step (initial secret
provisioning, DNS record, USB dongle), state it in `plan/` — never
hide it in a comment inside a module.

## 7. Terminal-only

No web UIs, no in-browser diagram renderers, no cloud dashboards for
core workflow (design/execute/review). `bd` for tracking, `hunk` for
diff review, `xi` for deploy. This constrains tool choice on purpose
— reduces context switching, keeps the loop tight.
