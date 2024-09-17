{pkgs, ...}: {
  catppuccin.pointerCursor = {
    enable = true;
  };
  gtk = {
    enable = true;
    font = {
      name = "Iosevka";
      size = 9;
    };
  };
  # home.pointerCursor = {
  #   package = pkgs.catppuccin-cursors.mochaDark;
  #   name = "Catppuccin-Mocha-Dark-Cursors";
  #   size = 24;
  #   gtk.enable = true;
  #   x11.enable = true;
  # };
}
