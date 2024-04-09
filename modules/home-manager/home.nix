{ config, ... }: {
  imports = [
    ./aliases.nix
    ./desktop/gtk.nix
    ./packages.nix
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
    xdg.enable = true;
    home.sessionVariables = {
      EDITOR = "nvim";
      # TODO: use firefox binary if nixOs profile is enabled
      BROWSER = "firefox-devedition";
    };
  };
}