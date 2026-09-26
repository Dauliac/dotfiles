{
  flake.modules.nixos.desktop = {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };
}
