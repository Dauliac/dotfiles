{
  flake.modules.homeManager.noctalia = {
    programs.noctalia-shell.settings.bar = {
      position = "left";
      opacity = 0.9;

      widgetsLeft = [
        "Launcher"
        "Tray"
      ];

      widgetsCenter = [ "Workspace" ];

      widgetsRight = [
        "Clock"
        "NotificationHistory"
        "Battery"
        "Volume"
        "Brightness"
        "ControlCenter"
      ];
    };
  };
}
