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
        ];

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
