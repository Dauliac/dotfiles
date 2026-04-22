{
  flake.modules.nixos.spongebob-gaming = {
    hardware = {
      nvidia = {
        modesetting.enable = true;
        open = false;
        nvidiaSettings = true;
      };
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
}
