{
  flake.modules.nixos.gary-gnome = { pkgs, ... }: {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "gary";
      };
    };

    # programs.niri.enable is owned by modules/nixos/niri.nix (shared
    # aspect, imported from host-gary).
    programs.kdeconnect.enable = true;
  };
}
