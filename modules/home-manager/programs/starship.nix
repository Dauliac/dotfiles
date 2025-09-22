_:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      cmd_duration = {
        min_time = 500;
      };
    };
  };
}
