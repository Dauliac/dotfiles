{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardening.nix
    ./secrets.nix
    ./boot.nix
    ./bluetooth.nix
    ./locales.nix
    ./sound.nix
    ./theme.nix
    ./comin.nix
  ];
  networking.networkmanager.enable = true;
  services.upower.enable = true;
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
    jdk21
    wl-clipboard
    firefox
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
  programs.zsh.enable = true;
  networking.firewall.enable = true;
  # BUG: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
  services.logrotate.checkConfig = false;
  services.flatpak = {
    enable = true;
    packages = [
      {
        appId = "app.zen_browser.zen";
        origin = "flathub";
      }
      {
        appId = "io.appflowy.AppFlowy";
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
          # Fix un-themed cursor in some Wayland apps
          XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
          # Force correct theme for some GTK apps
          # GTK_THEME = "Adwaita:dark";
        };
      };
    };
  };
  system.stateVersion = "24.11";
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
}
