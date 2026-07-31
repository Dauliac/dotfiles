{
  flake.modules.homeManager.widgets =
    { lib, ... }:
    {
      programs = {
        tofi = {
          enable = true;
          settings = {
            height = "20%";
            width = "35%";
            border-width = 4;
            corner-radius = 4;
            # font and colors managed by stylix
            font-size = lib.mkForce "16";
          };
        };
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
