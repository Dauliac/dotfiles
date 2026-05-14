{
  flake.modules.homeManager.noctalia = {
    programs.noctalia-shell.settings.general = {
      animationSpeed = 1.0;
      shadow = true;
      # font and monoFont managed by stylix
      clipboardHistory = true;
      volumeOverride = true;
    };
  };
}
