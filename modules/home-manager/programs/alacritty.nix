{...}: {
  programs.alacritty = {
    enable = true;
    catppuccin.enable = true;
    settings = {
      font = {
        normal.family = "Iosevka Nerd Font Mono";
      };
      selection = {
        save_to_clipboard = true;
      };
      window = {
        padding = {
          x = 3;
          y = 3;
        };
        dynamic_padding = true;
        opacity = 0.89;
      };
    };
  };
}
