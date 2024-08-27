{...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    catppuccin.enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red) ";
        vicmd_symbol = "[V](bold green) ";
      };
      cmd_duration = {min_time = 500;};
      git_branch = {symbol = "🌱 ";};

      git_state = {
        cherry_pick = "[🍒 PICKING](bold red)";
        merge = "[🔀 MERGE](bold red)";
      };

      git_commit = {
        commit_hash_length = 4;
        tag_symbol = "🔖 ";
      };
    };
  };
}
