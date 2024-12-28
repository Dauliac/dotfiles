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
    nixpkgs = {
      config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };
    };
    fonts.fontconfig.enable = true;
    xdg.enable = true;
    home.sessionVariables = {
      # TODO: use firefox binary if nixOs profile is enabled
      BROWSER = "firefox-devedition";
    };
  };
}
