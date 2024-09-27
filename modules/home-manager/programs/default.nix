{...}: {
  imports = [
    ./alacritty.nix
    ./bat.nix
    ./direnv.nix
    ./git.nix
    ./history.nix
    ./lazygit.nix
    ./neovim
    ./rio.nix
    ./pet.nix
    ./starship.nix
    ./wezterm.nix
    ./zellij.nix
    ./zsh.nix
    ./rio.nix
  ];
  programs.home-manager.enable = true;
  # NOTE: fast cd
  programs.zoxide = {
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
  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        body.bgColor = "default";
        # ui.skin = "transparent";
      };
    };
    # skins = {
    #   transparent = {
    #     k9s = {
    #       body = {
    #         bgColor = "default";
    #       };
    #       prompt = {
    #         bgColor = "default";
    #       };
    #       info = {
    #         sectionColor = "default";
    #       };
    #       dialog = {
    #         bgColor = "default";
    #         labelFgColor = "default";
    #         fieldFgColor = "default";
    #       };
    #       frame = {
    #         crumbs = {
    #           bgColor = "default";
    #         };
    #         title = {
    #           bgColor = "default";
    #           counterColor = "default";
    #         };
    #         menu = {
    #           fgColor = "default";
    #         };
    #       };
    #       views = {
    #         charts = {
    #           bgColor = "default";
    #         };
    #         table = {
    #           bgColor = "default";
    #           header = {
    #             fgColor = "default";
    #             bgColor = "default";
    #           };
    #         };
    #         xray = {
    #           bgColor = "default";
    #         };
    #         logs = {
    #           bgColor = "default";
    #           indicator = {
    #             bgColor = "default";
    #             toggleOnColor = "default";
    #             toggleOffColor = "default";
    #           };
    #         };
    #         yaml = {
    #           colonColor = "default";
    #           valueColor = "default";
    #         };
    #       };
    #     };
    #   };
    # };
  };
}
