{
  config,
  lib,
  inputs,
  ...
}: let
  inpt = inputs;
  cfg = config;
in {
  config.perSystem = {pkgs, ...}: {
    packages = {
      dev = pkgs.nixosTest rec {
        name = "test-infra-nixos";
        nodes.nixos = {config, ...}: let
          user = "dauliac";
        in {
          imports = [
            inpt.disko.nixosModules.disko
            inpt.home-manager.nixosModules.home-manager
            ../nixos/configuration.nix
            ../nixos/disko.nix
            {
              home-manager = {
                sharedModules = [
                  inpt.nix-index-db.hmModules.nix-index
                ];
                extraSpecialArgs = {inputs = inpt;};
              };
            }
          ];
          home-manager.users.dauliac = {
            imports = [
              ../home-manager/home.nix
            ];
            # TODO: should we init zsh history file
            # home.file."${config.xdg.dataHome}/zsh/zsh_history" = {
            #   source = builtins.toFile "history" "";
            #   recursive = true;
            # };
          };
          services.openssh.settings.PermitRootLogin = "yes";
          services.xserver.displayManager.autoLogin.enable = true;
          services.xserver.displayManager.autoLogin.user = user;
          services.xserver.displayManager.gdm.enable = lib.mkForce false;
          virtualisation = {
            graphics = true;
            qemu.options = ["-vga none -device virtio-gpu-pci"];
            # NOTE: these are finetuned for my personal computer only
            memorySize = 3000;
            cores = 5;
            sharedDirectories = {
              sources = {
                source = builtins.toString ../../.;
                target = "/mnt/sources";
              };
            };
          };
          # home-manager.users.${user} = {
          #   wayland.windowManager.hyprland = {
          #     settings = {
          #       "$mod" = "CTRL_SHIFT";
          #       debug = {disable_logs = false;};
          #       misc = {
          #         "force_default_wallpaper" = 0; # disable anime
          #         disable_hyprland_logo = 1;
          #       };
          #       "animations" = {
          #         enabled = false;
          #         first_launch_animation = false;
          #       };
          #     };
          #   };
          # };
        };
        testScript = ''
          nixos.succeed("wezterm start zsh -c 'exit 0'")
          nixos.succeed("ls")
        '';
      };
    };
  };
}
