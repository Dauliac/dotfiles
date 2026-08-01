{
  flake.modules.homeManager.history = { config, ... }: {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height=40%"
        "--layout=reverse"
        "--border"
      ];
      historyWidgetOptions = [
        "--sort"
        "--exact"
      ];
    };
    programs.zsh.history = {
      expireDuplicatesFirst = true;
      extended = true;
      ignoreAllDups = true;
      ignorePatterns = [
        "rm *"
        "pkill *"
        "ls *"
      ];
      path = "${config.xdg.dataHome}/zsh/zsh_history";
      save = 20000;
      share = true;
    };
  };
}
