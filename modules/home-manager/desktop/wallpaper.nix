{ config, ... }:
{
  programs.wpaperd = {
    enable = true;
    settings = {
      default = {
        path = ./wallpaper.jpg;
      };
    };
  };
  systemd.user.services.wpaperd = {
    Unit = {
      Description = "Start wallpaper.";
      PartOf = "graphical-session.target";
      After = "graphical-session.target";
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      ExecStart = "${config.programs.wpaperd.package}/bin/wpaperd";
    };
  };
}
