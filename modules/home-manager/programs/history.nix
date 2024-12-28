{config, ...}: {
  programs.mcfly = {
    enable = true;
    enableZshIntegration = true;
    keyScheme = "vim";
    fuzzySearchFactor = 5;
  };
  programs.zsh.history = {
    expireDuplicatesFirst = true;
    extended = true;
    ignoreAllDups = true;
    ignorePatterns = ["rm *" "pkill *" "ls *"];
    path = "${config.xdg.dataHome}/zsh/zsh_history";

    save = 20000;
    share = true;
  };
  home.sessionVariables = {
    MCFLY_PROMPT = "❯";
  };
}
