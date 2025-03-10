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
    ./gaming.nix
    ./theme.nix
    ./comin.nix
  ];
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  services.upower.enable = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      vaapiIntel
      vaapiVdpau
      intel-media-driver
      libvdpau-va-gl
    ];
  };
  services.displayManager.ly.enable = true;
  services.picom.vSync = "drm";
  services.printing.enable = true;
  users.users.dauliac = {
    isNormalUser = true;
    description = "dauliac";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "docker"
      "dialout"
    ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.dauliac_hashed_password.path;
  };
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
    inputs.zen-browser.packages."${pkgs.system}".default
  ];
  environment.variables = {
    VDPAU_DRIVER = lib.mkIf config.hardware.graphics.enable (lib.mkDefault "va_gl");
    LIBVA_DRIVER_NAME = "iHD";
  };
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  programs.zsh.enable = true;
  networking.firewall.enable = true;
  # BUG: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
  services.logrotate.checkConfig = false;
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
