{ inputs, ... }:
{
  flake.modules.nixos.host-spongebob = {
    imports = with inputs.self.modules.nixos; [
      base
      bluetooth
      boot
      comin
      desktop
      gaming
      hardening
      locales
      secrets
      sound
      theme
      users

      spongebob-boot
      spongebob-desktop
      spongebob-gaming
      spongebob-hardware
      spongebob-home-manager
    ];

    networking.hostName = "spongebob";

    fileSystems."/data" = {
      device = "/dev/disk/by-label/data";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
}
