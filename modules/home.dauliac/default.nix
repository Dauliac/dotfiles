{ inputs, ... }:
let
  secretsDir = ./.;
in
{
  flake.modules.homeManager.user-dauliac =
    {
      pkgs,
      config,
      ...
    }:
    {
      imports = with inputs.self.modules.homeManager; [
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
        ssh
        starship
        terminal-multiplexer
        alacritty
        ghostty
        kitty
        wezterm
        tmux
        yazi
        zsh
      ];

      programs.nixvim.imports =
        with inputs.self.modules.nixvim;
        [
          base
          completion
          dap
          editing
          git
          lang-devops
          lang-go
          lang-lua
          lang-misc
          lang-nix
          lang-python
          lang-rust
          lang-shell
          lang-typescript
          lang-web
          lsp
          lsp-plugins
          navigation
          opts
          ui
        ];

      xdg.mime.enable = true;
      sops.secrets = {
        gitDauliac = {
          sopsFile = secretsDir + "/gitconfig.enc.ini";
          path = "/home/dauliac/.config/git/dauliac.secrets.ini";
          format = "ini";
        };
        sshKey = {
          sopsFile = secretsDir + "/id_ed25519.enc";
          path = "/home/dauliac/.ssh/id_ed25519";
          format = "binary";
        };
        sshPubKey = {
          sopsFile = secretsDir + "/id_ed25519.enc.pub";
          path = "/home/dauliac/.ssh/id_ed25519.pub";
          format = "binary";
        };
      };
      programs.git.settings.include.path = config.sops.secrets.gitDauliac.path;

      home.packages =
        let
          music = with pkgs; [
            rosegarden
            ardour
            zam-plugins
            qpwgraph
            bespokesynth
            bristol
            chow-kick
            espeak
            geonkick
            industrializer
            vcv-rack
            cardinal
            drumkv1
            gnaural
            drumgizmo
          ];
          videoGames = with pkgs; [
            steam-tui
            steamcmd
          ];
        in
        with pkgs;
        [
          prismlauncher
          moonlight-qt
          brillo
          cava
          ffmpeg_4-full.bin
          termusic
          system76-firmware
          rclone
          ncpamixer
          pavucontrol
          pulsemixer
          gparted
          xdg-desktop-portal
          xdg-desktop-portal-gtk
          libreoffice
          signal-desktop
        ]
        ++ music
        ++ videoGames;
    };
}
