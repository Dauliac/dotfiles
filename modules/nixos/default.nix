{ inputs, ... }: {
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
        # Bridge for the shared `system.autoUpgrade.backend` switch — adds
        # only the `backend` option and force-disables nixos-upgrade.{service,timer}
        # when `backend = "ansnix"`. Inert by default (backend defaults to
        # "native"). Mirrors the option surface exposed by the system-manager
        # side (modules/system-manager/auto-upgrade.nix).
        inputs.self.modules.nixos.auto-upgrade
      ];

      boot.blacklistedKernelModules = [ "floppy" ];

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
      # System-wide gvfs (network mounts, MTP, trash-in-file-manager).
      # HM installs pkgs.gvfs per-user as a fallback for non-NixOS hosts;
      # on NixOS this is the canonical registration path.
      services.gvfs.enable = true;

      services.flatpak = {
        enable = true;
        # Run `flatpak update --noninteractive --assumeyes` at the end of
        # every `nixos-rebuild switch`. mkDefault so per-host configs can
        # opt out (e.g. laptops on spotty wifi).
        update.onActivation = lib.mkDefault true;
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

      # Weekly background update as belt-and-suspenders: catches hosts
      # (e.g. servers) that go weeks without a rebuild.
      systemd.services.flatpak-update = {
        description = "Update flatpak apps (weekly)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.flatpak}/bin/flatpak update --noninteractive --assumeyes";
        };
      };
      systemd.timers.flatpak-update = {
        description = "Weekly flatpak update timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          RandomizedDelaySec = "1h";
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
