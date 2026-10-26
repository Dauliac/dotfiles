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
          gary-osk
          gary-secrets
          gary-sleep
          gary-ssh
          gary-users

          gary-acme
          gary-adguard
          gary-bluetooth-hub
          gary-cloudflared
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
          inputs.self.modules.generic.display
        ];

      networking.hostName = "gary";

      # Living-room TV at viewing distance. Drives firefox devPixelsPerPx,
      # cursor size, noctalia bar sizing, and GTK/Qt scale env vars via the
      # display-constants aspect. The VM variant overrides this to 1.0 for
      # a laptop-sized sandbox.
      systemConstants.display.scale = 3.0;

      virtualisation.vmVariant = {
        # xi's nix-wrap replaces nix.package with a symlinkJoin that lacks
        # `pname`, which nix-daemon.nix:310 reads to check for lix. The real
        # host rebuilds via xi so the wrap matters there; the VM is throwaway
        # and only needs stock nix.
        programs.xi.nix.wrapAlias = lib.mkForce false;

        # xi's nix-lib adapter in HM scope traverses programs.nixvim to collect
        # nested libs, but nixvim's type is self-referential through
        # config.lib → infinite recursion. Mirror the system-manager guard at
        # modules/flake/system-configurations.nix:60-99: disable the adapter
        # and replay only the lib-function generation (no nested traversal).
        home-manager.sharedModules = [
          (
            { config, lib, ... }:
            let
              defs = config.nix-lib.lib or { };
              flatten =
                prefix: attrs:
                builtins.foldl' (
                  acc: name:
                  let
                    v = attrs.${name};
                    key = if prefix == "" then name else "${prefix}.${name}";
                  in
                  if v ? fn then
                    acc // { ${key} = v; }
                  else if builtins.isAttrs v then
                    acc // (flatten key v)
                  else
                    acc
                ) { } (builtins.attrNames attrs);
              flat = flatten "" defs;
              fns = builtins.foldl' (
                acc: key: lib.recursiveUpdate acc (lib.setAttrByPath (lib.splitString "." key) flat.${key}.fn)
              ) { } (builtins.attrNames flat);
            in
            {
              nix-lib.enable = lib.mkForce false;
              lib = builtins.mapAttrs (_: v: if builtins.isFunction v then { __functor = _self: v; } else v) fns;
            }
          )
        ];

        # No display manager inside the VM  -  autologin gary on tty1 so the
        # niri tty autostart (zsh profileExtra in modules/home-manager/desktop/
        # niri/session.nix) fires without manual login. The virtualisation
        # module leaves getty@tty1 declared but inactive (nothing pulls it
        # into multi-user.target by default when a GTK display is wired),
        # so attach it to multi-user.target explicitly.
        services.getty.autologinUser = lib.mkForce "gary";
        # getty@tty1 is a template-instance service. nixos's
        # `systemd.services."getty@tty1".wantedBy` does not reliably create
        # the symlink for template instances, so attach it via the target's
        # Wants list instead.
        systemd.targets.multi-user.wants = [ "getty@tty1.service" ];
        # pam_lastlog2 (new in nixpkgs 26.05) opens a SQLite DB at
        # /var/lib/lastlog2/lastlog2.db from login(1). The nixos module does
        # not pre-create the directory, so the first autologin on getty@tty1
        # fails with "System error" and the login shell exits before niri
        # autostart runs. Pre-create the state dir so pam_lastlog2 succeeds.
        systemd.tmpfiles.rules = [
          "d /var/lib/lastlog2 0755 root root -"
        ];

        # VM is a laptop-sized dev sandbox, not a TV, drop to 1.0 so Firefox,
        # cursor, and noctalia bar render at normal size.
        systemConstants.display.scale = lib.mkForce 1.0;

        systemConstants.gary.featureFlags.acme = lib.mkForce false;
        systemConstants.gary.featureFlags.cloudflared = lib.mkForce false;
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
        # Home Assistant also disabled in the VM: its sops.templates.
        # "hass-secrets.yaml" references the mqtt-homeassistant-password
        # placeholder, which the mosquitto-disabled VM never declares.
        systemConstants.gary.featureFlags.homeAssistant = lib.mkForce false;

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
          # Default is 1024 (1GB), which mkfs formats with only 65k inodes.
          # Firefox exhausts inodes before touching any real-looking disk cap
          # and falls back to "missing or inaccessible profile" because every
          # new file write returns ENOSPC. 8GB gives ~500k inodes which is
          # plenty for a daily driver session.
          diskSize = 8192;
        };
      };
    };
}
