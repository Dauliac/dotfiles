{
  flake.modules.nixos.spongebob-desktop = { pkgs, ... }: {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
    # programs.niri.enable is owned by modules/nixos/niri.nix (shared
    # aspect, imported from host-spongebob).
  };
}
