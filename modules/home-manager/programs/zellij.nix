_: {
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
    exitShellOnExit = true;
    extraConfig = ''
      load_plugins {
          "https://github.com/bezbac/zellij-tabula/releases/download/v0.2.0/zellij-tabula.wasm" {
              home_dir "/home/juliendauliac/"
          }
      }
    '';
  };
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
}
