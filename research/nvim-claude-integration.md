# Neovim ↔ Claude Code integration — plugin survey

Scope: what to install (if anything) in nixvim to make Neovim work well with Anthropic's `claude` CLI, given the user already runs `claude` in herdr panes.

## TL;DR

Install **`coder/claudecode.nvim`** and configure it with `terminal.provider = "external"` (or `"none"`). It is the only plugin in the ecosystem that implements Anthropic's real IDE-integration protocol — the same WebSocket-based MCP that Anthropic ships for VS Code and JetBrains — so a `claude` process running in a *separate herdr pane* auto-discovers Neovim, sees the active file, tracks the visual selection, and opens proposed edits as native `:diffthis` splits inside your buffer with undo. Every other plugin either (a) opens `claude` inside an nvim `:terminal` split (duplicating what herdr already gives you) or (b) bypasses the CLI and talks to the Anthropic API directly (loses your `claude` skills, plan mode, MCP servers, subscription auth). Runner-up: **`olimorris/codecompanion.nvim`** with its `claude_code` ACP adapter, if you want a chat-pane UX that isn't the CLI TUI. Skip `greggh/claude-code.nvim`, `avante.nvim`, and `magenta.nvim` for this stack — they don't solve the "claude runs in herdr, nvim runs next to it, keep them talking" problem.

## Comparison table

| Plugin | Wire protocol | Selection sync (auto) | Diff apply into buffer | Runs claude in nvim `:terminal`? | Works with claude in external pane (herdr) | In nixpkgs `vimPlugins` | Last commit |
|---|---|---|---|---|---|---|---|
| coder/claudecode.nvim | Anthropic IDE WebSocket + MCP (JSON-RPC 2.0, spec 2025-03-26) | Yes (broadcast; external CLI reads via `getCurrentSelection`) | Yes, native `diffthis`, `:w`/`:q` = accept/reject | Optional (snacks/native/external/none) | Yes — `provider = "external"` or `"none"` keeps WS server up, launch CLI anywhere | Yes | 2026-06-25 |
| olimorris/codecompanion.nvim | ACP (Zed's Agent Client Protocol) via `npx acp-claude-code` bridge; also HTTP adapters | Chat-scoped (send buffer/selection as slash-commands) | Yes (interactive diff preview for tool approval) | Chat is a nvim buffer, not a terminal | Partial — the ACP process is spawned by the plugin, not shared with a herdr pane | Yes | 2026-09-18 |
| greggh/claude-code.nvim | None — wraps `claude` in a `:terminal` buffer | No | No (only file-change autoreload) | Yes (this is its whole design) | Redundant with herdr | Yes | 2026-02-04 |
| yetone/avante.nvim | Anthropic HTTP API directly (also implements ACP for other agents) | Yes (Cursor-style) | Yes (one-click apply) | N/A (no CLI) | N/A — doesn't use `claude` CLI at all | No | 2026-09-18 |
| dlants/magenta.nvim | Anthropic SDK directly (Node.js/TS runtime) | Yes | Yes (via EDL edit DSL) | N/A | N/A | No | 2026-09-18 |
| folke/sidekick.nvim | Copilot LSP for NES + generic terminal launcher for many CLIs including `claude` | NES-only | NES-only diff UI | Yes for the CLI side | Redundant with herdr for the CLI side | Yes | active |

"In nixpkgs `vimPlugins`" was verified against `pkgs/applications/editors/vim/plugins/vim-plugin-names` on master.

## Per-plugin notes

### coder/claudecode.nvim — pick

- Reverse-engineered Anthropic's IDE-integration protocol; the plugin's `PROTOCOL.md` documents it: WebSocket + JSON-RPC 2.0 messages layered on MCP spec `2025-03-26`, lock file at `~/.claude/ide/[port].lock` (or `$CLAUDE_CONFIG_DIR/ide/[port].lock`), auth via a 128-bit hex token in header `x-claude-code-ide-authorization`, server bound to `127.0.0.1`. Environment variables `CLAUDE_CODE_SSE_PORT` and `ENABLE_IDE_INTEGRATION=true` are exported to the launched CLI.
- MCP tools implemented (IDE→Claude): `selection_changed`, `at_mentioned`. Tools exposed to Claude: `openFile`, `openDiff`, `getCurrentSelection`, `getLatestSelection`, `getOpenEditors`, `getWorkspaceFolders`, `getDiagnostics`, `checkDocumentDirty`, `saveDocument`, `close_tab`, `closeAllDiffTabs`, `executeCode` (Jupyter, mostly unimplemented in nvim).
- Terminal providers: `snacks` (default, needs `folke/snacks.nvim`), `native` (nvim built-in term), `external` (spawn a separate terminal app), `none` (no CLI at all — the WS server just runs). **Critical for your stack:** `provider = "none"` + starting `claude` inside your herdr pane works — the CLI reads the lock file, connects to Neovim, and gets buffer/selection/diagnostics. Verified via plugin docs: "The WebSocket server still starts and broadcasts work as usual. Launch the Claude CLI externally when desired."
- Diff workflow: Claude's `openDiff` opens a real Neovim diff view; `:w` accepts, `:q` rejects (or `<leader>aa` / `<leader>ad`); fires `User ClaudeCodeDiffOpened`/`Closed` autocmds so you can wire your own UI.
- Zero external Lua deps (pure `vim.loop`) beyond the optional snacks provider. Neovim ≥ 0.8.
- Last commit 2026-06-25 (as of research), 3.1k stars, released as `v0.3.0`. Actively maintained by Coder Inc.
- **Weakness:** selections are *broadcast*, not *pushed* — an external CLI has to call `getCurrentSelection` to fetch them; the in-editor providers (`snacks`/`native`) get slightly tighter focus/autofocus behavior (`focus_after_send` is a no-op in `external`/`none` modes). Not a blocker.
- Nixvim: no dedicated nixvim module; use `extraPlugins = [ pkgs.vimPlugins.claudecode-nvim ]` + `extraConfigLua`. `pkgs.vimPlugins.snacks-nvim` is also in nixpkgs.
- Source: <https://github.com/coder/claudecode.nvim>, protocol: <https://github.com/coder/claudecode.nvim/blob/main/PROTOCOL.md>

### olimorris/codecompanion.nvim — runner-up

- General AI-assistant plugin with chat / inline / agent workflows. Since v17.18.0 it speaks **ACP** (Zed's Agent Client Protocol) and ships a `claude_code` ACP adapter with name `"claude_code"`, type `"acp"`, launched via `command = "npx acp-claude-code"`. That bridge package translates ACP↔`claude` — it is not the same as Anthropic's own IDE protocol.
- Also has HTTP adapters for Anthropic, OpenAI, Copilot, Gemini, Ollama, xAI, DeepSeek, Mistral and ~10 others.
- MCP client support built in (separate from ACP).
- Diff review is an interactive UI with approval prompts. Multiple simultaneous chat sessions. Image/PDF input. Inline transforms via `:CodeCompanion`.
- Very active: last commit 2026-09-18, 6.9k stars, weekly releases.
- **Killer feature vs claudecode.nvim:** you get a chat buffer that isn't the raw CLI TUI (better for reading long responses in nvim keybindings) and multi-provider fallback.
- **Weakness for this stack:** the ACP adapter spawns its own `claude` subprocess via the bridge; you can't attach it to a `claude` you already have running in herdr. Requires `npx` / Node in PATH. ACP adapters are chat-only.
- In nixpkgs: `pkgs.vimPlugins.codecompanion-nvim`.
- Source: <https://github.com/olimorris/codecompanion.nvim>, ACP docs: <https://codecompanion.olimorris.dev/agent-client-protocol>

### greggh/claude-code.nvim — skip

- What it is: a toggleable `:terminal` split that runs the `claude` CLI. Adds `:ClaudeCode`, `:ClaudeCodeContinue`, `:ClaudeCodeResume`, `:ClaudeCodeVerbose`, auto-reloads buffers when files change on disk.
- No selection sync, no diff-into-buffer, no MCP/IDE protocol, no tool-use rendering. It's a terminal wrapper.
- Last commit 2026-02-04 (single fix after 7 months of dormancy from Jul 2025); 2.1k stars.
- **Verdict:** you already have herdr for terminal panes. This plugin duplicates that without adding anything nvim-native. Skip.
- Source: <https://github.com/greggh/claude-code.nvim>

### yetone/avante.nvim — skip for this use case

- Cursor-like sidebar and inline suggestions. Talks to Anthropic HTTP API directly (`ANTHROPIC_API_KEY`), plus OpenAI, Gemini, Azure, Cohere, Copilot. Recently added ACP support for other agents.
- 18.2k stars, very active.
- **Why skip:** does not use the `claude` CLI at all — so you lose plan mode, hooks, skills, MCP servers you've configured for Claude Code, and subscription billing. If you already pay for Claude Code the CLI, running avante means paying twice (API tokens) for a worse Claude Code experience. Not in nixpkgs `vimPlugins` (would need `extraPlugins` with a `fetchFromGitHub` + build step; requires Rust toolchain for its native library).
- Source: <https://github.com/yetone/avante.nvim>

### dlants/magenta.nvim — skip for this use case

- Tool-use-focused agent plugin; uses Anthropic SDK directly via a TypeScript core compiled to `dist/magenta.mjs`. Features EDL (Edit Description Language) DSL for token-efficient edits, sub-agent spawning (Docker/bwrap sandboxes), MCP *client* (connects to MCP servers, does not implement Anthropic's IDE MCP protocol).
- Requires Neovim ≥ 0.12.1, Node ≥ v24, a completion plugin.
- 466 stars, last commit 2026-09-18, active but niche.
- **Why skip:** same reason as avante — bypasses `claude` CLI, so no subscription reuse, no shared skills / hooks / MCP config. Also not in nixpkgs; you'd need to package the Node build.
- Source: <https://github.com/dlants/magenta.nvim>

### folke/sidekick.nvim — noted, partial fit

- Two independent features: (1) Copilot-LSP powered Next Edit Suggestions (NES) with a diff UI, (2) a generic CLI-launcher for Claude, Gemini, Grok, Codex, Copilot CLI with session persistence via tmux/zellij.
- The Claude CLI side is again just a terminal launcher — redundant with herdr. The NES side is Copilot-only, not Claude.
- Neovim ≥ 0.11.2. 2.8k stars. In nixpkgs.
- **Verdict:** if you *also* wanted Copilot NES, this earns its slot; for Claude Code specifically it doesn't beat claudecode.nvim.
- Source: <https://github.com/folke/sidekick.nvim>

## Recommendation

Install **`coder/claudecode.nvim`** in your nixvim config. Set the terminal provider to `"external"` (spawn a new terminal only when nvim asks) or `"none"` (nvim just runs the WS server; you keep launching `claude` from herdr panes as today). Either way the `claude` process discovers Neovim via the lock file and gains buffer/selection/diagnostics access + can request `openDiff` which lands as a real nvim diff split.

Concrete lazy.nvim spec (translate to nixvim `extraPlugins` + `extraConfigLua`, or vendor it under `modules/nixvim/`):

```lua
{
  "coder/claudecode.nvim",
  -- Only needed if provider = "snacks"; drop for "none"/"external".
  -- dependencies = { "folke/snacks.nvim" },
  config = function()
    require("claudecode").setup({
      -- Do NOT open claude inside nvim; herdr already owns terminal panes.
      terminal = { provider = "none" },
      -- Real-time selection push to any connected CLI.
      track_selection = true,
      -- Diff UX
      diff_opts = { layout = "vertical" }, -- or "unified" (needs nvim 0.9+)
    })
  end,
  cmd = {
    "ClaudeCodeStart", "ClaudeCodeStop", "ClaudeCodeStatus",
    "ClaudeCodeSend", "ClaudeCodeAdd", "ClaudeCodeTreeAdd",
    "ClaudeCodeDiffAccept", "ClaudeCodeDiffDeny", "ClaudeCodeCloseAllDiffs",
    "ClaudeCodeSelectModel",
  },
  keys = {
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: send selection" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: reject diff" },
    { "<leader>a+", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: add current file" },
  },
}
```

Nixvim skeleton (drop into `modules/nixvim/ai.nix` or similar):

```nix
{ pkgs, ... }: {
  extraPlugins = [ pkgs.vimPlugins.claudecode-nvim ];
  extraConfigLua = ''
    require("claudecode").setup({
      terminal = { provider = "none" },
      track_selection = true,
      diff_opts = { layout = "vertical" },
    })
  '';
  keymaps = [
    { mode = "v"; key = "<leader>as"; action = "<cmd>ClaudeCodeSend<cr>"; }
    { mode = "n"; key = "<leader>aa"; action = "<cmd>ClaudeCodeDiffAccept<cr>"; }
    { mode = "n"; key = "<leader>ad"; action = "<cmd>ClaudeCodeDiffDeny<cr>"; }
    { mode = "n"; key = "<leader>a+"; action = "<cmd>ClaudeCodeAdd %<cr>"; }
  ];
}
```

Then in a herdr pane, launch `claude` as usual — it will read `~/.claude/ide/*.lock`, connect, and you'll see `:ClaudeCodeStatus` report a live connection. Verify with `:checkhealth claudecode`.

**Runner-up caveat:** if the CLI TUI in a herdr pane starts feeling clunky for long response reading (scroll, copy, markdown rendering), add `codecompanion.nvim` alongside claudecode.nvim — they don't conflict. Use codecompanion's `claude_code` ACP adapter for chat, claudecode.nvim for the actual buffer/diff plumbing on your existing herdr-hosted CLI. That means running `npx acp-claude-code` on demand, which spawns a *second* claude process — different session from the herdr one.

## What you already get from herdr + no plugin

Today: `claude` in a herdr pane next to `nvim`. You copy-paste snippets, tell claude a file path, it edits the file on disk, `:e` or `:checktime` reloads. That's fine for straight Q&A but:
- Claude has zero awareness of your cursor, selection, unsaved changes, or LSP diagnostics unless you paste them.
- Edits land on disk — no in-buffer diff review with undo history preserved.
- Multi-file changes must be inspected via `git diff` outside nvim.

`claudecode.nvim` closes exactly these three gaps by exposing Neovim state over the same protocol Anthropic uses for VS Code. It does not replace herdr; it upgrades the pane already there.

`greggh/claude-code.nvim` and `sidekick.nvim`'s CLI mode, by contrast, *do* duplicate herdr — they're for people who want nvim to own the terminal too. Not you.

## Sources

- coder/claudecode.nvim repo: <https://github.com/coder/claudecode.nvim>
- coder/claudecode.nvim PROTOCOL.md (WebSocket/MCP details, lock file, tool list): <https://github.com/coder/claudecode.nvim/blob/main/PROTOCOL.md>
- greggh/claude-code.nvim repo: <https://github.com/greggh/claude-code.nvim>
- yetone/avante.nvim repo: <https://github.com/yetone/avante.nvim>
- olimorris/codecompanion.nvim repo: <https://github.com/olimorris/codecompanion.nvim>
- codecompanion ACP docs: <https://codecompanion.olimorris.dev/agent-client-protocol>
- codecompanion Claude Code ACP adapter discussion: <https://github.com/olimorris/codecompanion.nvim/discussions/2036>
- codecompanion v17.18.0 ACP release notes: <https://github.com/olimorris/codecompanion.nvim/discussions/2030>
- dlants/magenta.nvim repo: <https://github.com/dlants/magenta.nvim>
- folke/sidekick.nvim repo: <https://github.com/folke/sidekick.nvim>
- nixpkgs `vim-plugin-names` (verified availability of claudecode-nvim, claude-code-nvim, codecompanion-nvim, sidekick-nvim; avante-nvim and magenta-nvim absent): <https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/vim-plugin-names>
- Anthropic Claude Code IDE integration overview (VS Code / JetBrains reference): <https://docs.anthropic.com/en/docs/claude-code/ide-integrations>
