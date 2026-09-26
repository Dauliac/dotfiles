{ inputs, ... }:
{
  flake.modules.homeManager.herdr =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # Snapshot of what `herdr-agent-quota configure --apply` would write
      # into ~/.config/herdr/config.toml. Encoded here instead of letting
      # the plugin mutate the file at runtime — our design (openspec
      # herdr-plugins-declarative, spec herdr/plugin-registry) makes
      # config.toml a read-only Nix store symlink, which breaks the
      # plugin's runtime configure step with "Permission denied". Captured
      # 2026-09-17 from a fresh `configure --apply` run against
      # agent-quota v1.5.4. Re-capture on plugin bumps if the sidebar
      # layout or brand colors drift; see the `agent-quota-sidebar.toml`
      # header comment for the re-capture recipe.
      agentQuotaSidebar = builtins.fromTOML (
        builtins.readFile ../../packages/herdr-plugins/agent-quota-sidebar.toml
      );
    in
    {
      # kevinpita/herdr-nix owns the typed programs.herdr.settings.* tree
      # (auto-generated from herdr's config-reference.json) and the
      # programs.herdr.plugins.<name>.source option that registers
      # Nix-built plugin dirs via `herdr plugin link`. Pinned to a commit
      # sha in flake.nix — see openspec change herdr-plugins-declarative.
      imports = [ inputs.herdr-nix.homeModules.default ];

      programs.herdr = {
        enable = true;

        # Bypass kevinpita's `package.nix` and use our `pkgs.herdr` from
        # the `llm-agents` overlay (numtide/llm-agents.nix, cached at
        # cache.numtide.com). Kevinpita's build calls
        # `zig_0_15.fetchDeps { fetchAll = true; ... }` which nixpkgs-25.11
        # doesn't accept ("unexpected argument 'fetchAll'"); the module
        # itself works fine as long as it's fed a pre-built herdr binary.
        # If kevinpita's package.nix stops using `fetchAll`, drop this.
        package = pkgs.herdr;

        # Only override keys where herdr's defaults don't match the tmux muscle
        # memory declared in modules/home-manager/programs/tmux.nix
        # (prefix = C-a; splits on u/i; detach on d; rename on comma; Alt+1..9 tabs).
        # Everything else is left on herdr's built-in defaults.
        settings = {
          # Skip the first-run onboarding banner — nix owns this config, so
          # there's nothing to interactively choose.
          onboarding = false;

          keys = {
            prefix = "ctrl+a";
            split_horizontal = "prefix+u";
            split_vertical = "prefix+i";
            detach = "prefix+d";
            rename_tab = "prefix+,";
            indexed.tabs = "alt";
            # Vim-style workspace nav — herdr defaults to arrows for the 1-D
            # workspace list; k/j matches the hjkl muscle memory used for panes.
            navigate_workspace_up = "k";
            navigate_workspace_down = "j";

            # Plugin actions. Bindings for actions declared in each plugin's
            # herdr-plugin.toml [[actions]] section — herdr enforces that the
            # command id resolves to a known plugin_action or the binding is
            # a no-op at reload.
            command = [
              {
                key = "prefix+shift+q";
                type = "plugin_action";
                command = "herdr-agent-quota.open-settings";
                description = "Open agent-quota settings pane";
              }
            ] ++ agentQuotaSidebar.keys.command;
          };

          ui = {
            # Route background agent-state toasts through the OS notification
            # service — on this box that's noctalia, owner of
            # org.freedesktop.Notifications (see
            # modules/home-manager/desktop/noctalia/notification.nix). Default
            # is "off", so nothing pops when a background agent finishes /
            # blocks.
            toast.delivery = "system";

            # Distinct static glyphs for blocked / working / done / idle /
            # unknown instead of the compact colored dots — easier to
            # disambiguate agent state at a glance in the sidebar.
            status_indicators = "symbols";

            # Surface the detected agent (claude, codex, ...) in each split
            # pane's border when no manual pane name is set.
            show_agent_labels_on_pane_borders = true;

            # Reclaim a row when a workspace has exactly one tab — the
            # new-tab keybinding (prefix+c) still creates one when needed.
            hide_tab_bar_when_single_tab = true;

            # Sidebar rows for herdr-agent-quota's per-pane quota gauges.
            # Sourced from agent-quota-sidebar.toml — see the let-binding
            # for why this is snapshotted here instead of runtime-mutated.
            inherit (agentQuotaSidebar.ui) sidebar;
          };

          # Persist per-pane screen history across full server restarts, so a
          # `systemctl --user restart herdr` or crash doesn't nuke scrollback.
          experimental.pane_history = true;
        };

        # Declaratively-managed plugins — Nix owns the registry
        # (~/.config/herdr/plugins.json). Adding a plugin: define a new
        # entry in modules/packages/herdr-plugins/, expose it in the
        # collector's default.nix, then add one line here. NEVER run
        # `herdr plugin install` on this host — the registry is
        # regenerated on every activation and would drop imperative
        # entries. See openspec change herdr-plugins-declarative.
        plugins = {
          auto-title.source = pkgs.herdrPlugins.auto-title;
          agent-quota.source = pkgs.herdrPlugins.agent-quota;
        };
      };

      # Install herdr's Claude Code integration hook so Claude reports its
      # state (working/blocked/done) back to herdr's socket. Kevinpita's
      # module owns settings + plugins but not integrations, so this stays.
      # Idempotent: herdr rewrites the file each time.
      home.activation.herdrClaudeIntegration = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if PATH="$HOME/.nix-profile/bin:$PATH" command -v herdr >/dev/null 2>&1; then
          run --quiet $DRY_RUN_CMD $HOME/.nix-profile/bin/herdr integration install claude \
            || echo "herdr claude integration: install failed (non-fatal)"
        fi
      '';
    };
}
