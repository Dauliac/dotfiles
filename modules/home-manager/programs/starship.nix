_: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      cmd_duration = {
        min_time = 500;
        format = "took [$duration]($style) ";
      };
      time = {
        disabled = false;
        format = " [$time]($style) ";
        time_format = "%H:%M:%S";
        style = "bold yellow";
      };
      mise = {
        disabled = false;
        format = "[$symbol$health]($style) ";
        healthy_symbol = " ";
        unhealthy_symbol = "x";
      };
      direnv = {
        disabled = false;
        format = "[$symbol]($style)";
      };
    };
  };
}
