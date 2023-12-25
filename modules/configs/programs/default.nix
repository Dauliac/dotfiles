{ config, pkgs }:
let wrapNixGL = import ./nixGl.nix { inherit pkgs; };
in
{
  home-manager.enable = true;
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
}
