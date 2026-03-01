# Home-manager configuration for user: dauliac
# Auto-imported by import-tree - no imports needed
{ lib, ... }:
let
  secretsDir = ./.;
in
{
  config.dotfiles.home.userModules.dauliac = lib.mkAfter [
    (
      {
        pkgs,
        config,
        ...
      }:
      {
        xdg.mime.enable = true;
        sops = {
          secrets = {
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
        };
        programs.git.settings = {
          include = {
            inherit (config.sops.secrets.gitDauliac) path;
          };
        };

        home.packages =
          let
            music = with pkgs; [
              rosegarden
              ardour
              zam-plugins
              qpwgraph
              zam-plugins # NOTE: VST
              bespokesynth # NOTE: synth
              bristol # NOTE: synth
              chow-kick # NOTE: drum synth
              espeak # NOTE: speech synthesis
              geonkick # NOTE: drum synth
              industrializer # NOTE: drum synth
              vcv-rack # NOTE: modular synth
              cardinal # NOTE: modular synth
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
      }
    )
  ];
}
