{
  flake.modules.homeManager.alacritty = {
    programs.alacritty = {
      enable = true;
      settings = {
        # font and opacity managed by stylix
        selection.save_to_clipboard = true;
        window = {
          padding = {
            x = 3;
            y = 3;
          };
          dynamic_padding = true;
        };
      };
    };
  };
}
