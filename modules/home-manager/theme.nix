_:
let
  wallpaperPath = ./desktop/wallpaper.jpg;
in
{
  flake.modules.homeManager.theme = { pkgs, ... }: {
    stylix = {
      enable = true;
      autoEnable = true;
      polarity = "dark";
      image = wallpaperPath;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.iosevka;
          name = "Iosevka Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.nerd-fonts.iosevka;
          name = "Iosevka Nerd Font";
        };
        serif = {
          package = pkgs.nerd-fonts.iosevka;
          name = "Iosevka Nerd Font";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
        sizes = {
          terminal = 13;
          applications = 12;
          desktop = 11;
          popups = 12;
        };
      };

      opacity = {
        terminal = 0.89;
        applications = 1.0;
        desktop = 1.0;
        popups = 0.95;
      };

      targets = {
        # Neovim has custom catppuccin lua config with transparency overrides
        nixvim.enable = false;
        # Not running GNOME desktop from Nix — managed by Ubuntu system
        gnome.enable = false;
        # Disable KDE target — its XDG_CONFIG_DIRS override shadows /etc/xdg,
        # which prevents gnome-session from finding SettingsDaemon autostart files
        kde.enable = false;
      };
    };

    # Keep catppuccin module only for programs stylix doesn't cover
    catppuccin = {
      enable = true;
      flavor = "mocha";
      # Disable all catppuccin targets that conflict with stylix
      bat.enable = false;
      btop.enable = false;
      fzf.enable = false;
      # gtk removed from catppuccin/nix (upstream archived)
      k9s.enable = false;
      kitty.enable = false;
      lazygit.enable = false;
      starship.enable = false;
      tmux.enable = false;
      yazi.enable = false;
    };
  };
}
