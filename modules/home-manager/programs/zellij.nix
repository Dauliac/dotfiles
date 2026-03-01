{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.zellij = {
        enable = true;
        enableZshIntegration = false; # handled manually to skip TTY
        exitShellOnExit = true;
        extraConfig = ''
          load_plugins {
              "https://github.com/bezbac/zellij-tabula/releases/download/v0.2.0/zellij-tabula.wasm" {
                  home_dir "/home/juliendauliac/"
              }
          }
        '';
      };
      # Custom zellij auto-start: only in graphical terminals, not TTY
      programs.zsh.initContent = ''
        # Start zellij only in graphical terminals (not TTY)
        if [[ -z "$ZELLIJ" && "$TERM" != "linux" ]]; then
          zellij
          if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
            exit
          fi
        fi
      '';
      programs.sheldon = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          shell = "zsh";
          plugins = {
            zellij-tabula = {
              github = "bezbac/zellij-tabula";
              use = [ "{{ name }}.plugin.zsh" ];
              tag = "v0.2.0";
            };
          };
        };
      };
    })
  ];
}
