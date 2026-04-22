{
  flake.modules.homeManager.noctalia = {
    programs.noctalia-shell.settings.general = {
      animationSpeed = 1.0;
      shadow = true;
      font = "Iosevka Nerd Font";
      monoFont = "Iosevka Nerd Font Mono";
      clipboardHistory = true;
      volumeOverride = true;
    };
  };
}
