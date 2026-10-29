{
  # GitHub companion for the bar: `raycursive/github-prs` (community
  # plugin), the GitHub half of the two-companion setup. The GitLab half
  # is `tphilippot/git_companion` with `platform = "gitlab"`, which stays
  # work-laptop-local in modules/home.juliendauliac/default.nix because
  # it needs corp `glab` auth no personal host has.
  #
  # Why a SECOND plugin instead of a second git_companion widget:
  # git_companion's `platform` is a plugin-level `[[setting]]`, so it
  # lives in `plugin_settings."tphilippot/git_companion"` - one table per
  # plugin id, with no per-widget-instance override (noctalia's validator
  # rejects `plugin_settings."<id>:<entry>"` with "no loaded plugin with
  # this id"). Its single `[[service]]` also publishes to flat, unscoped
  # state keys (`prs_count`, `issues_count`, `username`, `status`). Two
  # git_companion widgets would therefore share one platform and one set
  # of counts, and render identically. Separate plugin ids are what give
  # us two independent settings tables and state namespaces.
  #
  # Unconditional, unlike myNoctalia.anytype / myNoctalia.calendar: those
  # are opt-in because they declare sops secrets whose absence FAILS
  # activation. A missing or unauthenticated `gh` only makes this widget
  # render an error glyph, so every host can carry it safely.
  flake.modules.homeManager.noctalia =
    {
      pkgs,
      lib,
      ...
    }:
    {
      # `gh` is the plugin's hard dependency (plugin.toml:
      # dependencies = ["gh", "xdg-open"]). It shells out to
      # `gh api graphql`, one request per non-empty rule.
      home.packages = [ pkgs.gh ];

      # Version note, because this bites when checking the schema:
      # noctalia pins the newest catalog entry its plugin API supports,
      # NOT the newest release. This box installs v0.3.0 (plugin API 9)
      # and logs why on startup:
      #
      #   installing 'raycursive/github-prs' v0.3.0 (plugin API 9);
      #   v0.3.1 needs plugin API 43 (supported range 3-30)
      #
      # So read the schema from the MATERIALIZED copy under
      # ~/.local/state/noctalia/plugins/materialized/community/github-prs,
      # not from the catalog repo's HEAD - the two can disagree. The keys
      # set below happen to be identical in 0.3.0 and 0.3.1; a future
      # noctalia that reaches API 43 may change that.

      programs.noctalia.settings = {
        plugins.enabled = lib.mkAfter [
          "raycursive/github-prs"
        ];

        # Plugin-level `[[setting]]` keys. See the long note in
        # modules/home.juliendauliac/default.nix for the general
        # plugin_settings-vs-widget rule; here `rules`,
        # `excluded_repositories` and `refresh_interval` are plugin-level,
        # while `glyph` and `hide_when_zero` are `[[widget.setting]]` and
        # belong in the widget table below.
        plugin_settings."raycursive/github-prs" = {
          # Each rule is a GitHub search fragment; the service prefixes
          # `is:pr is:open` and adds `archived:false` unless the rule
          # already mentions `archived:`. Results across rules are merged
          # and deduplicated, so author + review-requested cannot
          # double-count a PR that is both.
          #
          # This mirrors what the GitLab companion tracks on the other
          # side (`--author=@me` plus `--reviewer=@me`).
          rules = [
            "author:@me"
            "review-requested:@me"
          ];
          excluded_repositories = [ ];
          # Upstream default. Each refresh costs one GraphQL request per
          # rule, so this is deliberately slower than the GitLab
          # companion's 60s; `gh` is rate-limited per hour.
          refresh_interval = 180;
        };

        widget.github_prs = {
          type = "raycursive/github-prs:bar";
          glyph = "brand-github";
          # Keep the bar quiet when there is nothing open, matching the
          # herdr widget's hide_count_when_zero behaviour.
          hide_when_zero = true;
        };
      };
    };
}
