{ config, pkgs }: {
  enable = true;
  desktopEntries = {
    wezterm = {
      name = "WezTerm";
      genericName = "Termnial";
      exec = "${pkgs.wezterm}/bin/wezterm";
      terminal = false;
      categories = [ "System" "TerminalEmulator" "Utility" ];
      mimeType = [ "application/x-shellscript" ];
      icon = "${pkgs.wezterm}/share/icons/hicolor/256x256/apps/wezterm.png";
    };
  };
}
