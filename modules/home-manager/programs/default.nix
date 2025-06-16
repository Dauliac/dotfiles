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
    ./kubecolor.nix
    ./go.nix
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
    plugin = {
      plugins = {
      debug = {
        shortCut = "Shift-D";
        description = "Add debug container";
        scopes = [ "containers" ];
        command = "kubectl";
        background = false;
        args = [
          "debug"
          "-it"
          "--context"
          "$CONTEXT"
          "-n"
          "$NAMESPACE"
          "$POD"
          "--target"
          "$NAME"
          "--image=nicolaka/netshoot:v0.13"
          "--share-processes"
          "--"
          "bash"
        ];
      };
      };
    };
  };
  programs.btop = {
    enable = true;
  };

}
