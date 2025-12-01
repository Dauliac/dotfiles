{ config, ... }:
{
  imports = [
    ./aliases.nix
    ./packages.nix
    ./programs
    ./secrets.nix
    ./theme.nix
    ./patches.nix
  ];
  config = {
    home.stateVersion = "25.05";
    home.enableNixpkgsReleaseCheck = false;
    home.file."${config.xdg.configHome}" = {
      source = ./xdg-config;
      recursive = true;
    };
    fonts.fontconfig.enable = true;
    # xdg.enable = true;
    home.sessionVariables = {
      BROWSER = "zen";
    };
  };
}
