{ config, pkgs, inputs, ... }:
let wrapNixGL = import ./nixGl.nix { inherit pkgs; };
in
{
  xdg.enable = true;
  home.stateVersion = "23.05"; # Please read the comment before changing.
  home.packages = import ./packages.nix { inherit pkgs; };
  home.file."${config.xdg.configHome}" = {
    source = ../../dotfiles/xdg-config;
    recursive = true;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "bat";
  } // (import ./direnv.nix { inherit pkgs; }).shellEnv
  // (import ./history.nix { inherit config pkgs; }).shellEnv;
  home.shellAliases = import ./aliases.nix { inherit pkgs; };
  programs.home-manager.enable = true;
  programs = {
    zsh = import ./zsh.nix { inherit config pkgs; };
    git = import ./git.nix { inherit config pkgs; };
    starship = import ./starship.nix { };
    direnv = (import ./direnv.nix { inherit config pkgs; }).dotfiles;
    # NOTE: fast cd
    pazi = {
      enable = true;
      enableZshIntegration = true;
    };
    # NOTE: cheat sheet
    tealdeer = { enable = true; };
    # NOTE: cheat sheet
    navi = {
      enable = true;
      enableZshIntegration = true;
    };
    pet = import ./pet.nix { inherit pkgs; };
    bat = import ./bat.nix { inherit pkgs; };
    zellij = {
      enable = true;
      enableZshIntegration = true;
    };
    htop = { enable = true; };
    wezterm = import ./wezterm.nix { package = (wrapNixGL pkgs.wezterm); };
    jq = { enable = true; };
    k9s = { enable = true; };
    mcfly = (import ./history.nix { inherit config pkgs; }).mcfly;
  };
}
