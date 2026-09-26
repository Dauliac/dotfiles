# Declarative Claude Code skills management via Nix / home-manager

Research question: is there an existing tool — a Nix module, home-manager
module, flake, community project, or first-party Anthropic tool — for
declaratively managing Claude Code / AI coding-agent "skills" via Nix
home-manager?

Location note: this file lives under `docs/research/` because the repo has
no dedicated `research/` root at the top level (there is a `research/`
directory, but it's used for other content). `docs/` already contains
adjacent narrative material (`docs/statewright/`), so this fits the
convention.

---

## 1. TL;DR

- **Yes — home-manager itself now ships a native `programs.claude-code`
  module** with a dedicated `skills` option (and `plugins`, `marketplaces`,
  `agents`, `commands`, `hooks`, `rules`, `outputStyles`, `settings`,
  `mcpServers`, plus `*Dir` variants). It was introduced 2025-08-15 and
  `programs.claude-code.skills` specifically was announced 2025-11-25.
  Source: `nix-community/home-manager` → `modules/programs/claude-code/`
  ([options.nix](https://github.com/nix-community/home-manager/blob/master/modules/programs/claude-code/options.nix),
  [news 2025-11-25](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2025/11/2025-11-25_02-56-51.nix)).
- Two community flakes go further with **curated marketplace/skill
  registries** on top of the native module:
  [dryvist/nix-claude-code](https://github.com/dryvist/nix-claude-code)
  (imports `github:anthropics/skills` and ~10 other skill/plugin flakes as
  `inputs`, exposes `lib.discoverSkills`, `lib.discoverCommands`,
  `lib.discoverAgents`, `lib.wrapCommandsAsSkills`) and
  [tienedev/harnix](https://github.com/tienedev/harnix) (pinned
  `"name@marketplace"` registry, per-tool + per-project scopes, renders
  for both Claude Code and Pi).
- **`numtide/llm-agents.nix` — the flake this repo already uses — packages
  three third-party skill-manager CLIs (`openskills`, `claude-plugins`,
  `skills`) but does not itself expose a home-manager `skills` module.**
  The declarative surface still has to come from home-manager or from
  nix-claude-code / harnix.
- **Anthropic does not ship a first-party CLI or package manager for
  skills.** Skills are just directories on disk; distribution is manual
  (git), via plugin marketplaces (community-owned), enterprise managed
  settings, or claude.ai account sync
  ([code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)).
- **Recommended path for this repo:** migrate the hand-rolled
  `mkSkillFiles` loop in `modules/home-manager/ai/capability/skills.nix` to
  `programs.claude-code.skills` (native, upstream-maintained, symlinks
  entire skill directories in one line each). The two categorisation
  arrays (`engineering`, `productivity`, `support`) can be collapsed into
  a single attrset keyed by skill name pointing at the local dir; the
  `anytypeToolboxSkills` block already fits the same shape. No behaviour
  change, ~50 fewer lines, drops the custom
  `unsafeDiscardStringContext` + `listFilesRecursive` plumbing. See §5.

---

## 2. What we searched

- **web** — `nix home-manager module claude code skills declarative`,
  `"claude-code" nix flake home-manager module 2026`, `"openskills"
  universal skills loader AI coding agents`, `"claude-plugins" CLI tool
  managing plugins install`, `"anthropic-agent-skills" github flake
  input`.
- **Anthropic docs** — [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)
  (was `docs.claude.com/en/docs/claude-code/skills`, 301'd).
- **GitHub source read via `gh api` / `gh search`** —
  `nix-community/home-manager` (`modules/programs/claude-code/*`, news
  entries), `dryvist/nix-claude-code`, `tienedev/harnix`,
  `flyinggrizzly/claude-config.nix`, `roman/mcps.nix`, `anthropics/skills`,
  `Kamalnrf/claude-plugins`, `numman-ali/openskills`,
  `numtide/llm-agents.nix`.
- **Local read** — `modules/home-manager/ai/capability/skills.nix`,
  `modules/home-manager/ai/capability/default.nix`, and the skill tree
  under `modules/home-manager/ai/capability/skills/`.

---

## 3. Findings by category

### 3.1 First-party (Anthropic) tooling for skills

Nothing dedicated. The Anthropic docs
([code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills))
list four storage locations —
`~/.claude/skills/<name>/SKILL.md` (personal),
`.claude/skills/<name>/SKILL.md` (project-committed),
`<managed-settings-dir>/.claude/skills/` (enterprise MDM), and
`<plugin>/skills/<name>/SKILL.md` (bundled inside a plugin) — and four
distribution methods: manual git, plugins + marketplaces (`/plugin
install <name>@<marketplace>`), enterprise managed settings, and
claude.ai account sync into `~/.claude/skills/synced/`.

The doc is explicit that there is **no built-in package manager, no
`claude skill install` subcommand, and no declarative manifest**. Every
tool that fills that gap is community-owned.

Anthropic does maintain a curated skill collection —
[`anthropics/skills`](https://github.com/anthropics/skills) — with
directories like `frontend-design`, `pdf`, `xlsx`, `pptx`, `mcp-builder`,
`skill-creator`, `webapp-testing`, `slack-gif-creator`, etc. under
`skills/`. This repo is what most of the Nix loaders (nix-claude-code,
harnix, dryvist) consume via `inputs.<name>.url = "github:anthropics/skills"; flake = false;`.

### 3.2 `numtide/llm-agents.nix` — does it manage skills?

**No — it packages the *tools*, not the *skills*.** llm-agents.nix ships
Nix packages for agent runtimes (Claude Code, Codex, Gemini CLI, Herdr,
Beads, Gascity, etc.) plus a `Skills & Plugins` category that packages
three third-party CLI skill-managers:

- `claude-plugins` — CLI + registry from
  [Kamalnrf/claude-plugins](https://github.com/Kamalnrf/claude-plugins)
  (`claude-plugins.dev`, ~11.9k plugins / 63k skills indexed as of
  2026-09).
- `openskills` — universal skills loader from
  [numman-ali/openskills](https://github.com/numman-ali/openskills),
  npm-installable, writes SKILL.md into `~/.claude/skills/<name>/` or
  `.agent/skills/<name>/` (multi-agent mode).
- `skills` — a third open-source installer for skills across coding
  agents.

There is **no home-manager module in llm-agents.nix for wiring skill
markdown into `~/.claude/skills/`**. If we want declarative, we still
need either home-manager's native `programs.claude-code.skills` or a
community flake on top of it.

### 3.3 Home-manager native module (`programs.claude-code.*`)

**This is the answer for most of the question.** The module lives at
[`modules/programs/claude-code/{default,options,lib}.nix`](https://github.com/nix-community/home-manager/tree/master/modules/programs/claude-code)
in `nix-community/home-manager`. Timeline:

- 2025-08-15 — module introduced (`programs.claude-code` with `settings`,
  `commands`, `agents`, `hooks`, `mcpServers`)
  ([news 2025-08-15](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2025/08/2025-08-15_15-51-02.nix)).
- 2025-11-25 — `programs.claude-code.skills` added
  ([news 2025-11-25](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2025/11/2025-11-25_02-56-51.nix)).
- 2026-04-08 — `memory.text` / `memory.source` renamed to `context`
  ([news 2026-04-08](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2026/04/2026-04-08_12-00-00.nix)).
- 2026-08-06 — `enableMcpIntegration` added
  ([news 2026-08-06](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2026/08/2026-08-06_01-29-34.nix)).

The `skills` option, verbatim from
[options.nix](https://github.com/nix-community/home-manager/blob/master/modules/programs/claude-code/options.nix):

```nix
skills = mkOption {
  type = with lib.types; either (attrsOf (either lines path)) path;
  default = { };
  # If an attribute set is used, the attribute name becomes the
  # skill directory name, and the value is either:
  # - Inline content as a string (creates skills/<name>/SKILL.md)
  # - A path to a file (creates skills/<name>/SKILL.md)
  # - A path to a directory (creates skills/<name>/ with all files)
  # This also accepts Nix store paths, for example a skill directory
  # from a package.
  # If a path is used, it is expected to contain one folder per
  # skill name, each containing a SKILL.md. The directory is
  # symlinked into the skills/ subdirectory of configDir.
};
```

Example from the option docstring:

```nix
programs.claude-code.skills = {
  xlsx = ./skills/xlsx/SKILL.md;
  data-analysis = ./skills/data-analysis;      # whole dir
  pdf-processing = ''
    ---
    name: pdf-processing
    description: ...
    ---
    # PDF Processing
  '';
  beads = "${pkgs.beads.src}/claude-plugin/skills/beads";
};
```

That last form — a skill dir extracted from a package source — is
exactly the shape we already use for `anytype-toolbox` in this repo.

The full option surface is `enable`, `package`, `finalPackage`,
`enableMcpIntegration`, `configDir`, `settings`, `context`, `plugins`,
`marketplaces`, `agents`, `commands`, `hooks`, `rules`, `outputStyles`,
`skills`, `lspServers`, plus `agentsDir` / `commandsDir` / `hooksDir` /
`rulesDir` etc. Both attrset and dir-path forms work. The module was
carefully designed to handle Claude Code's symlink bug — inspected
via `default.nix`, most files are written through activation copies,
not raw home.file symlinks that Claude Code can't dereference. This is
the same workaround `flyinggrizzly/claude-config.nix` was doing before
it archived itself in favour of the upstream module.

### 3.4 Community Nix flakes / dotfile repos that build on the native module

Ranked by relevance to this repo:

- **[`dryvist/nix-claude-code`](https://github.com/dryvist/nix-claude-code)** —
  the closest match to "declaratively manage skills + plugins + marketplaces
  as a curated stack". Ingests ~10 flake inputs (`anthropic-agent-skills`
  → `github:anthropics/skills`, `claude-plugins-official`, `bills-claude-skills`,
  `bitwarden-marketplace`, `cc-dev-tools`, `cc-marketplace`,
  `claude-code-plugins-plus`, `wshobson/agents`, `secondsky/claude-skills`,
  etc.) all with `flake = false`, and exposes `lib.discoverSkills`,
  `lib.discoverCommands`, `lib.discoverAgents`,
  `lib.wrapCommandsAsSkills`. Composes with home-manager natively. Every
  enabled plugin is version-pinned via `flake.lock`.
- **[`tienedev/harnix`](https://github.com/tienedev/harnix)** — declares
  skills/plugins via `ai.plugins.claude-code.user`,
  `ai.plugins.claude-code.project.<path>`, and
  `ai.plugins.claude-code.sources` overrides. Uses an internal
  `registry.nix` that maps `"name@marketplace"` → `fetchFromGitHub`.
  Renders for both Claude Code (`~/.claude/plugins/`,
  `~/.claude.json`) **and Pi** (`~/.pi/agent/mcp.json`). Also renders a
  shared `ai.agents.<name>` block into per-tool frontmatter for both
  targets. `settings.mutable = true` toggle for handling Claude Code's
  runtime writes.
- **[`flyinggrizzly/claude-config.nix`](https://github.com/flyinggrizzly/claude-config.nix)** —
  **archived** in favour of home-manager's native support. Manages
  commands + memory + mcpServers by copying (not symlinking) around the
  Claude Code symlink bug. Historically interesting only.
- **[`sadjow/home-manager`](https://github.com/sadjow/home-manager)** —
  personal dotfiles using the native module. Good example
  configuration, not a reusable library.
- **[`natsukium/mcp-servers-nix`](https://github.com/natsukium/mcp-servers-nix)** —
  MCP-server-only, but its `examples/home-manager/flake.nix` shows the
  native `programs.claude-code` module wiring.
- **[`0xc000022070/agentic-flake`](https://github.com/0xc000022070/agentic-flake)** —
  "Composable agent skills and project-scoped environments for Nix".
  Template-driven (`nix flake init -t github:0xc000022070/agentic-flake`
  then `nix develop`). Skill-scoped devshells rather than a home-manager
  loader; not a direct fit for this repo's model.

### 3.5 Non-Nix but Nix-adjacent skill managers (wrappable)

- **[`Kamalnrf/claude-plugins`](https://github.com/Kamalnrf/claude-plugins)**
  — TypeScript CLI, registry at claude-plugins.dev, sub-tools
  `claude-plugins` (plugin manager) and `skills-installer` (skill
  installer). Multi-agent: Claude, Cursor, Windsurf, OpenCode, Codex,
  VS Code, Amp, Goose, Letta, Gemini CLI, and more. Install a skill
  imperatively: `npx skills-installer install @anthropics/claude-code/frontend-design`.
- **[`numman-ali/openskills`](https://github.com/numman-ali/openskills)**
  — npm-installable universal loader (`npm i -g openskills`), Apache 2.0.
  Reads any GitHub repo of SKILL.md dirs. `--universal` flag installs
  into `.agent/skills/` so multiple agents (Claude Code, Cursor,
  Aider, Codex, ...) can all read via `AGENTS.md`.
- **[`yibie/skills-manager`](https://github.com/yibie/skills-manager)** —
  native macOS app (GUI, not automatable).

All three are packaged by `llm-agents.nix` under `Skills & Plugins`.
They're imperative — mutations to `~/.claude/skills/` fight a declarative
home-manager setup unless scoped to a separate dir.

---

## 4. Gap analysis vs. this repo's current approach

**What `modules/home-manager/ai/capability/skills.nix` does today**
(read 2026-09-21):

1. Three curated string lists (`engineering`, `productivity`,
   `support`, ~90 skill names total).
2. `mkSkillFiles parentDir name` walks a skill directory recursively via
   `lib.filesystem.listFilesRecursive`, strips the store-path prefix with
   `builtins.unsafeDiscardStringContext`, and emits `{ name = ".claude/skills/<name>/<rel>"; value.source = path; }` entries.
3. `mkFlakeSkills flakeName subdir names` does the same for a flake
   input's source tree (currently only `anytype-toolbox`).
4. Everything is concatenated into a single `home.file` attrset.

Comparison against the native `programs.claude-code.skills` option:

| Concern                                   | Current in-tree loader | `programs.claude-code.skills` |
| ----------------------------------------- | ---------------------- | ----------------------------- |
| Ship whole skill dir (SKILL.md + refs + scripts) | Yes (recursive walk) | Yes (`value = ./skills/xxx`) |
| Ship a single SKILL.md                    | Yes                    | Yes (`value = ./x/SKILL.md`)  |
| Inline skill body from a Nix string       | No                     | Yes                           |
| Consume a subdir from a flake input       | Custom helper needed   | Yes (`value = "${inputs.x}/path"`) |
| Consume a subdir from a package source    | Would need a helper    | Yes (`value = "${pkgs.beads.src}/..."`) |
| Handles Claude Code's symlink-read bug    | Delegates to home.file (symlink) — probably fine for SKILL.md, potentially fragile for helper scripts | Handled upstream via activation copy where needed |
| Ships alongside `commands`, `agents`, `hooks`, `rules`, `outputStyles`, `settings`, `mcpServers` under one option namespace | Split across `modules/home-manager/ai/capability/{mcp,permissions,skills,statewright}.nix` and `workspace/{settings,rules,skill-compliance}.nix` | All one module; upgrade path shares tests + news |
| Upstream owns updates                     | No                     | Yes                           |
| Custom code to maintain                   | ~50 LOC + a `builtins.unsafeDiscardStringContext` gotcha | ~0 LOC |

**What we would save by migrating**: the whole `mkSkillFiles` /
`mkFlakeSkills` mini-framework and the string-context escape hatch. What
we would gain: consistent option surface with the rest of the module
(so `mcp.nix`, `permissions.nix`, `statewright.nix`, `runtime-claude.nix`
and the `workspace/settings.nix` merger could also collapse in a
follow-up), plus alignment with news entries and upstream bug fixes for
Claude Code quirks.

**What we would NOT get from a straight migration**: the curated
marketplace flake inputs from `dryvist/nix-claude-code`, and the shared
per-agent rendering (Claude Code + Pi) from `tienedev/harnix`. If either
becomes interesting we can layer them on top of the native module later
without redoing the migration.

---

## 5. Recommendation

**(a) Adopt `programs.claude-code.skills`** from home-manager's native
`programs.claude-code` module. Optionally, in a second step, also adopt
`agents`, `commands`, `hooks`, `rules`, `outputStyles`, `settings`, and
`mcpServers` to collapse the surrounding `capability/*.nix` files.

Justification:

1. It's upstream, discoverable via `man home-configuration.nix` and
   `home-manager option programs.claude-code.skills`, and covered by
   home-manager's news system so we're notified when the option changes.
2. Its `skills` type
   (`either (attrsOf (either lines path)) path`) subsumes every case our
   current loader handles (single SKILL.md, whole skill dir, dir from a
   flake input via `${inputs.foo}/x`, dir from a package via
   `${pkgs.foo.src}/x`), plus inline Nix strings we don't currently
   support but might want (e.g. templated per-host skills).
3. The two categorisation arrays (`engineering`, `productivity`,
   `support`) are already flat — they exist only to route to the right
   category subdirectory. That routing collapses into
   `programs.claude-code.skills = lib.mapAttrs' (n: cat: { name = n; value = ./skills/${cat}/${n}; }) skillCatalog;`
   or equivalent. Comments currently attached to the list literals move
   to `# ` lines above each attr, or into a sibling doc.
4. `dryvist/nix-claude-code` and `tienedev/harnix` are strictly wrappers
   around the same option surface. Adopting either right now would add a
   flake input for a curated marketplace we don't currently need
   (upstream `github:anthropics/skills` isn't referenced by any of our
   90-odd skill entries — they're all local first-party). If we later
   decide to consume the Anthropic marketplace, we can either add the
   `inputs.anthropic-agent-skills.url = "github:anthropics/skills"; flake = false;` input directly (native-module-friendly) or bring in
   nix-claude-code as a library. No lock-in either way.
5. Rejecting (b) "write our own `mkSkills` helper": we already have one;
   the value the built-in adds is *not being our helper*.
6. Rejecting (c) "status quo": works but pays the maintenance tax of a
   custom recursive-walk-with-string-context-hack for a problem
   home-manager now solves in one option.

Follow-up beads worth filing after this research lands, but out of scope
for this doc:

- Migrate `modules/home-manager/ai/capability/skills.nix` to
  `programs.claude-code.skills`.
- Evaluate collapsing `mcp.nix`, `permissions.nix`,
  `workspace/settings.nix`, `workspace/rules.nix`, and
  `runtime-claude.nix` into a single `programs.claude-code.*`
  attribute set.
- Decide whether to also declare `plugins` (there's already a
  `.claude/plugins/cache/` in-repo — could be pinned via
  `programs.claude-code.marketplaces` + `plugins` instead of live-fetched).

---

## 6. Sources

- [nix-community/home-manager — `modules/programs/claude-code/options.nix`](https://github.com/nix-community/home-manager/blob/master/modules/programs/claude-code/options.nix)
- [home-manager news 2025-08-15 — `programs.claude-code` introduced](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2025/08/2025-08-15_15-51-02.nix)
- [home-manager news 2025-11-25 — `programs.claude-code.skills` added](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2025/11/2025-11-25_02-56-51.nix)
- [home-manager news 2026-04-08 — memory → context rename](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2026/04/2026-04-08_12-00-00.nix)
- [home-manager news 2026-08-06 — `enableMcpIntegration`](https://github.com/nix-community/home-manager/blob/main/modules/misc/news/2026/08/2026-08-06_01-29-34.nix)
- [Anthropic docs — Skills](https://code.claude.com/docs/en/skills)
- [anthropics/skills — curated first-party skill collection](https://github.com/anthropics/skills)
- [dryvist/nix-claude-code](https://github.com/dryvist/nix-claude-code)
- [tienedev/harnix](https://github.com/tienedev/harnix)
- [flyinggrizzly/claude-config.nix (archived)](https://github.com/flyinggrizzly/claude-config.nix)
- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)
- [Kamalnrf/claude-plugins](https://github.com/Kamalnrf/claude-plugins)
- [numman-ali/openskills](https://github.com/numman-ali/openskills)
- [roman/mcps.nix](https://github.com/roman/mcps.nix) (MCP-only)
- [natsukium/mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix)
- [0xc000022070/agentic-flake](https://github.com/0xc000022070/agentic-flake)
- [sadjow/home-manager](https://github.com/sadjow/home-manager)
- [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix) (packaging, not config)
- Local: `modules/home-manager/ai/capability/skills.nix`,
  `modules/home-manager/ai/capability/default.nix`.
