{
  # Catppuccin Frappe base surfaces + Peach as the primary accent. The
  # built-in "Catppuccin" preset ships Mocha shades, so we declare a
  # custom palette in palettes.nix and point the theme source at it.
  # See docs.noctalia.dev/v5/theming.
  flake.modules.homeManager.noctalia = {
    programs.noctalia.settings.theme = {
      mode = "dark";
      source = "custom";
      custom_palette = "catppuccin-frappe-peach";
      pure_black_dark = false;
    };
  };
}
