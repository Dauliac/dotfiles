{ inputs, ... }:
{
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.self.modules.nixos.shell
        # inputs.catppuccin.nixosModules.catppuccin  # blocked: upstream uses services.displayManager.generic (newer nixpkgs)
        inputs.comin.nixosModules.comin
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.nixflix.nixosModules.default
        inputs.nur.modules.nixos.default
        inputs.sops-nix.nixosModules.sops
      ];

      networking.networkmanager.enable = true;
      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;
      hardware.bluetooth.enable = true;
      services.picom.vSync = "drm";
      services.printing.enable = true;
      nix = {
        settings = {
          system-features = [
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
          ];
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
        optimise.automatic = true;
        gc = {
          automatic = true;
          persistent = true;
          dates = "012:15";
          options = "-d";
        };
      };
      environment.systemPackages = with pkgs; [
        bash
        git
        curl
        overskride
        htop
        pipewire.jack
        sbctl
        wl-clipboard
      ];
      environment.variables = {
        VDPAU_DRIVER = lib.mkIf config.hardware.graphics.enable (lib.mkDefault "va_gl");
        LIBVA_DRIVER_NAME = "iHD";
        PATH = "$XDG_DATA_HOME/npm-packages/bin:$HOME/.local/bin/:$PATH";
      };
      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
      networking.firewall.enable = true;
      services.logrotate.checkConfig = false;
      services.flatpak = {
        enable = true;
        packages = [
          {
            appId = "app.zen_browser.zen";
            origin = "flathub";
          }
          {
            appId = "dev.vencord.Vesktop";
            origin = "flathub";
          }
        ];
        overrides = {
          global = {
            Context.sockets = [
              "wayland"
              "!x11"
              "!fallback-x11"
            ];
            Environment = {
              XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
            };
          };
        };
      };
      system.stateVersion = "25.05";
      virtualisation = {
        waydroid.enable = true;
        podman = {
          enable = true;
          defaultNetwork.settings.dns_enabled = true;
        };
        docker = {
          enable = true;
        };
      };

      services.spice-vdagentd.enable = true;
      services.qemuGuest.enable = true;
    };
}
