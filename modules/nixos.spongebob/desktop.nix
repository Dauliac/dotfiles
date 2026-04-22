{
  flake.modules.nixos.spongebob-desktop =
    { pkgs, ... }:
    {
      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
          user = "greeter";
        };
      };
      programs.niri.enable = true;
    };
}
