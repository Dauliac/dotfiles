{ config, pkgs, inputs, ... }: {
  home.stateVersion = "23.05"; # Please read the comment before changing.
  home.packages = import ./packages.nix { inherit pkgs; };
  home.file."${config.xdg.configHome}" = {
    source = ../../dotfiles/xdg-config;
    recursive = true;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "bat";
    XDG_DATA_DIRS = "/\${HOME}/.nix-profile/share:$XDG_DATA_DIRS";
  } // (import ./programs/direnv.nix { inherit pkgs; }).shellEnv
  // (import ./programs/history.nix { inherit config pkgs; }).shellEnv;
  home.shellAliases = import ./aliases.nix { inherit pkgs; };
  xdg = import ./xdg.nix { inherit config pkgs; };
  programs = import ./programs/default.nix { inherit config pkgs; };
}
