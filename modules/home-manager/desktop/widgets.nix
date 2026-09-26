{
  flake.modules.homeManager.widgets = { ... }: {
    programs = {
      hyprpanel = {
        enable = true;
        settings = {
          bar.launcher.autoDetectIcon = true;
          bar.workspaces.show_icons = true;
          menus.clock = {
            time = {
              military = true;
              hideSeconds = true;
            };
            weather.unit = "metric";
          };
          menus.dashboard.directories.enabled = false;
          menus.dashboard.stats.enable_gpu = true;
          theme.bar.transparent = true;
          # theme.font managed by stylix
        };
      };
    };
  };
}
