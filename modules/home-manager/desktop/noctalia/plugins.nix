{
  flake.modules.homeManager.noctalia = {
    programs.noctalia-shell.settings.plugins.states = {
      "privacy-indicator" = true;
      "assistant-panel" = true;
      "catwalk" = true;
      "screen-recorder" = true;
      "screenshot" = true;
      "weekly-calendar" = true;
      "hyprland-steam-overlay" = true;
      "fancy-audiovisualizer" = true;
      "clipper" = true;
    };
  };
}
