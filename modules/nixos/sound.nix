{ lib, ... }:
{
  config.dotfiles.nixos.sharedModules = lib.mkAfter [
    (_: {
      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    })
  ];
}
