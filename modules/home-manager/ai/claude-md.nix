{
  flake.modules.homeManager.claude-md = _: {
    # Nix-owns ~/.claude/CLAUDE.md (user-level Claude Code global instructions —
    # applies to every session in every project).
    #
    # Tradeoff: `codegraph install --refresh` cannot mutate a nix-managed
    # symlink into the store. If codegraph is bumped in llm-agents.nix, hand-
    # sync the CodeGraph block below with `codegraph install --print-config`
    # (or the equivalent block-generator) before switching. Current block is
    # verbatim from codegraph v1.5.0.
    home.file.".claude/CLAUDE.md" = {
      force = true;
      text = ''
        <!-- CODEGRAPH_START -->
        ## CodeGraph

        In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

        - **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
        - **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

        If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
        <!-- CODEGRAPH_END -->

        ## Coding-agent pipeline

        Terminal-only stack. **Design → beads → execution → review.** Design produces immutable artifacts (spec-kit); beads owns live execution state; agents execute bead-by-bead; hunk reviews the diff.

        - **Design** (non-trivial features only — skip for single-file changes, known-cause bug fixes, spikes):
          `/speckit.constitution <principles>` → `memory/constitution.md` (once per repo)
          `/speckit.specify <feature>` → `spec/<slug>.md` (WHAT)
          `/speckit.plan <tech + architecture>` → `plan/<slug>.md` (HOW)
          **DO NOT run `/speckit.tasks`** — decompose the plan into beads instead. Beads is a strictly better task tracker (graph, state, priority, `bd ready`).

        - **Execution** (all task tracking, always):
          `bd create --title="…" --description="…" --type=task --priority=<0-4>` (0=critical, 2=medium, 4=backlog)
          `bd link <blocked> <blocker>` — dependency edges
          `bd ready` → `bd update <id> --claim` → implement → `bd close <id>`
          `bd note <id> "…"` for reasoning; `bd remember "insight"` for cross-session knowledge.
          **Never** use TodoWrite / TaskCreate / MEMORY.md / markdown checklists for tasks.

        - **Semantic search**: prefer `codegraph_explore` MCP or `codegraph explore "<question>"` over grep/find. Fall back to grep only when `.codegraph/` is absent.

        - **Diff review**: for edits >30 lines or multi-file, suggest `hunk diff --watch` in a herdr/tmux pane. For tiny edits, plain `git diff` is faster.

        - **Sandboxing** (automatic): Bash calls are wrapped by `fence` via `PreToolUse:Bash` hook. If a call is denied, revise or ask the user — do NOT try to bypass.

        - **Cost + viz** (suggest, don't launch): `ccusage claude daily|monthly|blocks`, `bv` for the beads graph, `herdr agent list` for pane state.

        - **Multi-agent orchestration**: when the user drives via `gc` (gascity), work is routed via `gc sling <target> <bead|text>`. `gc bd` wraps beads correctly for rig context. Otherwise stay agent-native with `bd` directly.

        - **Excluded on purpose**: `agentsview` (web UI), `crit` (browser UI) — terminal-only stack. Do not suggest them.
      '';
    };
  };
}
