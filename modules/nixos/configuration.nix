{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardening.nix
    ./secrets.nix
    ./boot.nix
    ./bluetooth.nix
    ./locales.nix
  ];
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
    };
  };
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [vaapiIntel vaapiVdpau intel-media-driver libvdpau-va-gl];
  };
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.picom.vSync = "drm";
  services.printing.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
    wireplumber.extraConfig = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = ["hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag"];
      };
    };
  };
  users.users.dauliac = {
    isNormalUser = true;
    description = "dauliac";
    extraGroups = ["networkmanager" "wheel" "audio" "video"];
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
      experimental-features = ["nix-command" "flakes"];
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
    git
    curl
    overskride
    htop
    pipewire.jack
    sbctl
    jdk21
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
  system.stateVersion = "23.11";
}
