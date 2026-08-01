{ inputs, ... }: {
  flake.modules.nixos.host-gary =
    {
      config,
      lib,
      ...
    }:
    {
      imports =
        with inputs.self.modules.nixos;
        [
          base
          bluetooth
          boot
          comin
          desktop
          hardening
          locales
          xi
          secrets
          sound
          theme
          users

          gary-boot
          gary-gaming
          gary-gnome
          gary-hardware
          gary-home-manager
          gary-nixflix
          gary-secrets
          gary-sleep
          gary-ssh
          gary-users

          gary-acme
          gary-adguard
          gary-bluetooth-hub
          gary-home-assistant
          gary-mosquitto
          gary-esphome
          gary-zigbee2mqtt
          gary-matter-server
          gary-airplay
          gary-airplay-uxplay
          gary-airplay-shairport
          gary-reverse-proxy
        ]
        ++ [
          inputs.self.modules.generic.gary-constants
          inputs.self.modules.generic.proprietary-flag
        ];

      networking.hostName = "gary";

      virtualisation.vmVariant = {
        systemConstants.gary.featureFlags.acme = lib.mkForce false;
        systemConstants.gary.featureFlags.reverseProxy = lib.mkForce true;

        networking.extraHosts =
          let
            inherit (config.systemConstants) gary;
            domain = gary.domain.public;
            localDomain = gary.domain.local;
            enabledServices = lib.filterAttrs (_: svc: svc.enable) gary.services;
          in
          lib.concatStringsSep "\n" (
            [
              "127.0.0.1 ${domain}"
              "127.0.0.1 ${localDomain}"
            ]
            ++ (lib.mapAttrsToList (_: svc: "127.0.0.1 ${svc.subdomain}.${domain}") enabledServices)
            ++ (lib.mapAttrsToList (_: svc: "127.0.0.1 ${svc.subdomain}.${localDomain}") enabledServices)
          );

        sops.defaultSopsFile = lib.mkForce "/dev/null";
        sops.validateSopsFiles = false;
        sops.secrets = lib.mkForce {
          dauliac_hashed_password = { };
          gary_hashed_password = { };
          dauliac_ssh_pub_key = { };
        };

        # Nixflix is enabled on real gary. The VM variant disables it because the
        # arr services need /data mount + SOPS secrets that a throwaway VM lacks.
        systemConstants.gary.featureFlags.nixflix = lib.mkForce false;
        systemConstants.gary.featureFlags.nixflixVpn = lib.mkForce false;
        systemConstants.gary.featureFlags.mosquitto = lib.mkForce false;
        systemConstants.gary.featureFlags.esphome = lib.mkForce false;
        systemConstants.gary.featureFlags.zigbee2mqtt = lib.mkForce false;
        systemConstants.gary.featureFlags.matterServer = lib.mkForce false;
        systemConstants.gary.featureFlags.haArrIntegration = lib.mkForce false;

        users.users.dauliac = {
          hashedPasswordFile = lib.mkForce null;
          initialPassword = lib.mkForce "test";
        };
        users.users.gary = {
          hashedPasswordFile = lib.mkForce null;
          initialPassword = lib.mkForce "test";
        };

        system.activationScripts.dauliacAuthorizedKeys = lib.mkForce "";

        virtualisation = {
          memorySize = 4096;
          cores = 4;
          graphics = true;
        };
      };
    };
}
