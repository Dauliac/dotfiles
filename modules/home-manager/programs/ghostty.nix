_: {
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    systemd.enable = true;
    settings = {
      font-family = "Iosevka Nerd Font Mono";
      background-opacity = 0.89;
      selection-clear-on-copy = true;
      window-decoration = false;
    };
  };
}
