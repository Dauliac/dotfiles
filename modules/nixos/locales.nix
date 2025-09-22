_:
{
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
  location.provider = "geoclue2";
  services.geoclue2.enable = true;
  hardware.brillo.enable = true;
  # services.clight = {
  #   enable = true;
  #   settings = {
  #     verbose = true;
  #     backlight.disabled = true;
  #     dpms.timeouts = [
  #       900
  #       300
  #     ];
  #     dimmer.timeouts = [
  #       870
  #       270
  #     ];
  #     gamma.long_transition = true;
  #     keyboard.disabled = true;
  #     screen.disabled = true;
  #   };
  # };
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "altgr-intl";
    };
  };
}
