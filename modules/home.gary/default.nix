{ inputs, ... }: {
  flake.modules.homeManager.user-gary =
    {
      lib,
      config,
      ...
    }:
    let
      proprietaryEnabled = config.systemConstants.proprietary.enable;
    in
    {
      imports =
        with inputs.self.modules.homeManager;
        [
          base
          aliases
          packages
          programs-base
          secrets
          theme
          desktop
          gtk
          wallpaper
          wayland
          widgets
          niri
          niri-kiosk
          noctalia
          ai
          bacon
          bat
          direnv
          eza
          git
          go
          history
          kubecolor
          lazygit
          xi
          neovim
          neovim-packages
          pet
          pueue
          starship
          alacritty
          ghostty
          kitty
          wezterm
          tmux
          herdr
          yazi
          zsh
        ]
        ++ [
          inputs.self.modules.generic.gary-constants
          inputs.self.modules.generic.proprietary-flag
          inputs.self.modules.generic.display
          # Service catalog entries (generic scope, shared with NixOS).
          # Firefox bookmarks consume these via config.systemConstants.gary.services.
          inputs.self.modules.generic.gary-service-adguard
          inputs.self.modules.generic.gary-service-bazarr
          inputs.self.modules.generic.gary-service-esphome
          inputs.self.modules.generic.gary-service-hass
          inputs.self.modules.generic.gary-service-jellyfin
          inputs.self.modules.generic.gary-service-jellyseerr
          inputs.self.modules.generic.gary-service-lidarr
          inputs.self.modules.generic.gary-service-prowlarr
          inputs.self.modules.generic.gary-service-qbittorrent
          inputs.self.modules.generic.gary-service-radarr
          inputs.self.modules.generic.gary-service-sonarr
          inputs.self.modules.generic.gary-service-zigbee2mqtt
        ];

      # Session env vars that make GTK/Qt apps follow the host's declared
      # display scale (set per host under `systemConstants.display.scale`).
      home.sessionVariables = config.systemConstants.display.toolkitEnv;

      programs.nixvim.imports = with inputs.self.modules.nixvim; [
        base
        lsp
        opts
      ];

      home.stateVersion = "25.05";

      programs.zsh.initContent = lib.mkForce "";

      services.flatpak = {
        enable = true;
        packages = lib.optionals proprietaryEnabled [
          {
            appId = "com.google.Chrome";
            origin = "flathub";
          }
        ];
      };
    };
}
