{ config, ... }:
{
  imports = [
    ./aliases.nix
    ./desktop/gtk.nix
    ./packages.nix
    ./programs
    ./secrets.nix
    ./theme.nix
  ];
  config = {
    home.stateVersion = "24.11";
    home.enableNixpkgsReleaseCheck = false;
    home.file."${config.xdg.configHome}" = {
      source = ./xdg-config;
      recursive = true;
    };
    fonts.fontconfig.enable = true;
    xdg.enable = true;
    home.sessionVariables = {
      BROWSER = "zen";
    };
  };
}
