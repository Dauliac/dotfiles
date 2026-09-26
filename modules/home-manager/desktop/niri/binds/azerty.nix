{
  # AZERTY (fr / fr-latin9) digit-row → workspace bindings. On this
  # layout the unshifted top row emits `& é " ' ( - è _ ç` rather than
  # `1..9`, so `Mod+1..9` never fires when fr is the active xkb layout.
  # We bind the actual keysyms directly here.
  #
  # Coexists with ./qwerty.nix; both are always loaded because their
  # keysyms don't collide — the one matching the current layout wins.
  flake.modules.homeManager.niri = {
    programs.niri.settings.binds = {
      "Mod+ampersand".action.focus-workspace = 1;   # &  (fr top-row "1")
      "Mod+eacute".action.focus-workspace = 2;      # é
      "Mod+quotedbl".action.focus-workspace = 3;    # "
      "Mod+apostrophe".action.focus-workspace = 4;  # '
      "Mod+parenleft".action.focus-workspace = 5;   # (
      "Mod+minus".action.focus-workspace = 6;       # -
      "Mod+egrave".action.focus-workspace = 7;      # è
      "Mod+underscore".action.focus-workspace = 8;  # _
      "Mod+ccedilla".action.focus-workspace = 9;    # ç
      "Mod+Ctrl+ampersand".action.move-column-to-workspace = 1;
      "Mod+Ctrl+eacute".action.move-column-to-workspace = 2;
      "Mod+Ctrl+quotedbl".action.move-column-to-workspace = 3;
      "Mod+Ctrl+apostrophe".action.move-column-to-workspace = 4;
      "Mod+Ctrl+parenleft".action.move-column-to-workspace = 5;
      "Mod+Ctrl+minus".action.move-column-to-workspace = 6;
      "Mod+Ctrl+egrave".action.move-column-to-workspace = 7;
      "Mod+Ctrl+underscore".action.move-column-to-workspace = 8;
      "Mod+Ctrl+ccedilla".action.move-column-to-workspace = 9;
    };
  };
}
