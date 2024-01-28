{ config, pkgs }: {
  widgets = import ./widgets.nix { inherit config pkgs; };
  wayland = import ./wayland.nix { inherit config pkgs; };
  services = import ./services.nix { inherit config pkgs; };
}
