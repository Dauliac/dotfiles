{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (
      { pkgs, ... }:
      {
        users = {
          groups = {
            gary = { };
          };
          users = {
            gary = {
              isNormalUser = true;
              description = "Media user";
              extraGroups = [
                "networkmanager"
                "wheel"
                "audio"
                "video"
                "docker"
                "dialout"
              ];
              shell = pkgs.zsh;
            };
          };
        };
      }
    )
  ];
}
