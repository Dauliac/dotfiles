{
  flake.modules.nixos.gary-gnome = { pkgs, ... }: {
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "gary";
      };
    };

    programs.niri.enable = true;
    programs.kdeconnect.enable = true;
  };
}
