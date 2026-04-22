{
  flake.modules.nixos.gary-airplay =
    { config, lib, ... }:
    lib.mkIf config.systemConstants.gary.featureFlags.airplay {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
      };
    };

    networking.firewall.allowedUDPPorts = [
      5353
    ];

    users.users.gary.extraGroups = [ "audio" ];
  };
}

