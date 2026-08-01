{
  flake.modules.homeManager.herdr =
    {
      pkgs,
      lib,
      ...
    }:
    let
      tomlFormat = pkgs.formats.toml { };
      # Only override keys where herdr's defaults don't match the tmux muscle
      # memory declared in modules/home-manager/programs/tmux.nix
      # (prefix = C-a; splits on u/i; detach on d; rename on comma; Alt+1..9 tabs).
      # Everything else is left on herdr's built-in defaults.
      config = {
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
        };
      };
    in
    {
      xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" config;

      # Install herdr's Claude Code integration hook so Claude reports its
      # state (working/blocked/done) back to herdr's socket. The hook is a
      # versioned shell script owned by herdr — we can't lock its contents
      # from nix without brittleness, so run the upstream installer on
      # activation. Idempotent: herdr rewrites the file each time.
      home.activation.herdrClaudeIntegration = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if PATH="$HOME/.nix-profile/bin:$PATH" command -v herdr >/dev/null 2>&1; then
          run --quiet $DRY_RUN_CMD $HOME/.nix-profile/bin/herdr integration install claude \
            || echo "herdr claude integration: install failed (non-fatal)"
        fi
      '';
    };
}
