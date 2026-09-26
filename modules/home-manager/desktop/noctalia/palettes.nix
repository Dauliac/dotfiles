{
  # Catppuccin Frappe with the Peach accent as primary.
  #
  # Hexes are the canonical Frappe tokens from github.com/catppuccin/catppuccin.
  # Noctalia stores each entry as a file under ~/.config/noctalia/palettes/,
  # so this attrset's key becomes the `custom_palette` name in colors.nix.
  # JSON schema: mPrimary/mOnPrimary/… (see src/theme/cli.cpp).
  flake.modules.homeManager.noctalia = {
    programs.noctalia.customPalettes.catppuccin-frappe-peach = {
      dark = {
        mPrimary = "#ef9f76";
        mOnPrimary = "#232634";
        mSecondary = "#8caaee";
        mOnSecondary = "#232634";
        mTertiary = "#a6d189";
        mOnTertiary = "#232634";
        mError = "#e78284";
        mOnError = "#232634";
        mSurface = "#303446";
        mOnSurface = "#c6d0f5";
        mSurfaceVariant = "#414559";
        mOnSurfaceVariant = "#b5bfe2";
        mOutline = "#737994";
        mShadow = "#232634";
        mHover = "#ef9f76";
        mOnHover = "#232634";
        terminal = {
          normal = {
            black = "#51576d";
            red = "#e78284";
            green = "#a6d189";
            yellow = "#e5c890";
            blue = "#8caaee";
            magenta = "#f4b8e4";
            cyan = "#81c8be";
            white = "#b5bfe2";
          };
          bright = {
            black = "#626880";
            red = "#e78284";
            green = "#a6d189";
            yellow = "#e5c890";
            blue = "#8caaee";
            magenta = "#f4b8e4";
            cyan = "#81c8be";
            white = "#a5adce";
          };
          foreground = "#c6d0f5";
          background = "#303446";
          cursor = "#f2d5cf";
          cursorText = "#232634";
          selectionFg = "#232634";
          selectionBg = "#f2d5cf";
        };
      };
    };
  };
}
