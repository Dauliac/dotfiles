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
  ];
  nixpkgs.config.allowUnfree = true;
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [vaapiIntel vaapiVdpau intel-media-driver libvdpau-va-gl];
    driSupport32Bit = true;
  };
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.picom.vSync = "drm";
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "altgr-intl";
    };
  };
  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };

  location.provider = "geoclue2";
  # provide location
  services.geoclue2.enable = true;

  hardware.brillo.enable = true;
  services.clight = {
    enable = true;
    settings = {
      verbose = true;
      backlight.disabled = true;
      dpms.timeouts = [900 300];
      dimmer.timeouts = [870 270];
      gamma.long_transition = true;
      keyboard.disabled = true;
      screen.disabled = true;
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
      experimental-features = ["nix-command" "flakes"];
    };
    auto-optimise-store = true;
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
  ];
  environment.variables = {
    VDPAU_DRIVER = lib.mkIf config.hardware.opengl.enable (lib.mkDefault "va_gl");
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
  system.stateVersion = "23.11"; # Did you read the comment?
}
