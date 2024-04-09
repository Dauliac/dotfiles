{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./alacritty.nix
    ./bat.nix
    ./direnv.nix
    ./git.nix
    ./history.nix
    ./lazygit.nix
    ./pet.nix
    ./starship.nix
    ./wezterm.nix
    ./zellij.nix
    ./zsh.nix
  ];
  programs.home-manager.enable = true;
  # NOTE: fast cd
  programs.pazi = {
    enable = true;
    enableZshIntegration = true;
  };
  # NOTE: cheat sheet
  programs.tealdeer = {enable = true;};
  # NOTE: cheat sheet
  programs.navi = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.jq = {enable = true;};
  programs.k9s = {enable = true;};
  programs.alacritty = {enable = true;};
}
