{ config, pkgs }: {
  programs = {
    # Add 
    # eww = {
    #   enable = true;
    #   configDir = ../../../dotfiles/eww;
    # };
    wofi.enable = true;
    wpaperd = {
      enable = true;
      settings = {
        eDP-1 = {
          path = "/home/foo/Pictures/Wallpaper";
          apply-shadow = true;
        };
        DP-2 = {
          path = "/home/foo/Pictures/Anime";
          sorting = "descending";
        };
      };
    };
  };
}
