{
  # Enable a couple of community theme templates so external apps pick up
  # the palette declared in colors.nix.
  #
  #   discord    → writes CSS into every Discord fork's themes/ dir
  #                (Vesktop is covered: templates.discord_*_vesktop write
  #                $XDG_CONFIG_HOME/vesktop/themes/*.css).
  #   zen-browser → writes userChrome.css + userContent.css and runs
  #                 apply.sh to symlink them into every Zen profile.
  #
  # Catalog ids come straight from the community-templates repo
  # (github.com/noctalia-dev/community-templates); noctalia fetches the
  # manifests from api.noctalia.dev/templates on first run.
  flake.modules.homeManager.noctalia = {
    programs.noctalia.settings.theme.templates = {
      enable_builtin_templates = true;
      enable_community_templates = true;
      community_ids = [
        "discord"
        "zen-browser"
      ];
    };
  };
}
