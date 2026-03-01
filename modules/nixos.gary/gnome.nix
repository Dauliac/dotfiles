{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (
      { pkgs, ... }:
      {
        # Auto-login directly into niri (no greeter)
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.niri}/bin/niri-session";
              user = "gary";
            };
          };
        };

        # Enable niri compositor
        programs.niri.enable = true;
      }
    )
  ];
}
