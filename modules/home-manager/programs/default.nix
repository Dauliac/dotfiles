{ config
, pkgs
, ...
}:
let
  # TODO: fix nixgl integration
  # wrapNixGL = import ./nixGl.nix {inherit pkgs;};
in
{
  imports = [
    ./alacritty.nix
    ./bat.nix
    ./direnv.nix
    ./git.nix
    ./history.nix
    ./pet.nix
    ./starship.nix
    ./wezterm.nix
    ./zsh.nix
  ];
  programs.home-manager.enable = true;
  # NOTE: fast cd
  programs.pazi = {
    enable = true;
    enableZshIntegration = true;
  };
  # NOTE: cheat sheet
  programs.tealdeer = { enable = true; };
  # NOTE: cheat sheet
  programs.navi = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.htop = { enable = true; };
  programs.jq = { enable = true; };
  programs.k9s = { enable = true; };
  programs.alacritty = { enable = true; };
}
