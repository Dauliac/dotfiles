{ config, pkgs, ... }: {
  mcfly = {
    enable = true;
    enableZshIntegration = true;
    keyScheme = "vim";
    fuzzySearchFactor = 5;
  };
  shellEnv = { MCFLY_PROMPT = "❯"; };
  zsh = {
    expireDuplicatesFirst = true;
    extended = true;
    ignoreAllDups = true;
    ignorePatterns = [ "rm *" "pkill *" "ls *" ];
    path = "${config.xdg.dataHome}/zsh/zsh_history";
    save = 20000;
    share = true;
  };
}
