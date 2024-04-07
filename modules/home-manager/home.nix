{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./desktop
    ./packages.nix
    ./xdg.nix
    ./aliases.nix
    ./programs
    ./secrets.nix
  ];
  config = {
    home.stateVersion = "23.05";
    home.file."${config.xdg.configHome}" = {
      source = ./xdg-config;
      recursive = true;
    };
    fonts.fontconfig.enable = true;
    home.sessionVariables = {
      EDITOR = "nvim";
      # TODO: use firefox binary if nixOs profile is enabled
      BROWSER = "firefox-devedition";
    };
  };
}
