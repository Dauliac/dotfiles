{ lib, ... }:
{
  boot = {
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    initrd.systemd.enable = true;
    loader.systemd-boot.enable = lib.mkForce false;
  };
}
