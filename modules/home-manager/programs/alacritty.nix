{...}: {
  programs.alacritty = {
    enable = true;
    settings = {
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
