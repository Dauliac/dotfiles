{ config, pkgs, inputs, ... }: {
  home.stateVersion = "23.05"; # Please read the comment before changing.
  home.packages = import ./packages.nix { inherit inputs pkgs; };
  home.file."${config.xdg.configHome}" = {
    source = ../../dotfiles/xdg-config;
    recursive = true;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "bat";
  } // (import ./programs/direnv.nix { inherit pkgs; }).shellEnv
  // (import ./programs/history.nix { inherit config pkgs; }).shellEnv;
  home.shellAliases = import ./aliases.nix { inherit pkgs; };
  xdg = import ./xdg.nix { inherit config pkgs; };
  programs = import ./programs/default.nix { inherit config pkgs; }
    // (import ./desktop/default.nix { inherit config pkgs; }).widgets.programs;
  services = (import ./desktop/default.nix { inherit config pkgs; }).services
    // {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
  };
  wayland = (import ./desktop/default.nix { inherit config pkgs; }).wayland;
}
