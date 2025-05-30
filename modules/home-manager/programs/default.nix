{ ... }:
{
  imports = [
    ./alacritty.nix
    ./bat.nix
    ./direnv.nix
    ./git.nix
    ./history.nix
    ./lazygit.nix
    ./neovim
    ./pet.nix
    ./starship.nix
    ./wezterm.nix
    ./zellij.nix
    ./zsh.nix
    ./eza.nix
    ./yazi.nix
  ];
  programs.home-manager.enable = true;
  # NOTE: fast cd
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  # NOTE: cheat sheet
  programs.tealdeer = {
    enable = true;
  };
  # NOTE: cheat sheet
  programs.navi = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.jq = {
    enable = true;
  };
  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        body.bgColor = "default";
      };
    };
  };
}
