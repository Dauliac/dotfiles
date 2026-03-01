{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.spongebob = lib.mkAfter [
    (_: {
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
    })
  ];
}
