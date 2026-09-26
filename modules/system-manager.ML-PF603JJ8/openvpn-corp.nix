{ inputs, ... }:
{
  # Corp OpenVPN profile, rendered from sops-encrypted secrets at activation.
  #
  # Certificate material (ca / cert / key) is deployed from per-file
  # sops-encrypted blobs. The keyfile itself is a `sops.templates` entry
  # so it can interpolate `corp_email` + `corp_password` (from the root
  # secrets.yaml) without baking the AD password into a static template.
  #
  # Rotate the AD password by editing `secrets.yaml` and re-deploying;
  # no re-encryption of the nmconnection file needed.
  #
  # Sensitive corp identifiers — split-tunnel CIDRs, VPN remote endpoint,
  # NM connection UUID — live in `secrets.yaml` (keys `corp_routes`,
  # `corp_remote`, `corp_uuid`) so this file discloses no corp topology.
  # Refresh the CIDRs by harvesting from a working laptop with
  # `~/.cache/claude/scratch/vpn_extract_routes.sh corp`, then
  # `sops set secrets.yaml '["corp_routes"]' "\"$(cat routes.txt)\""`.
  # `corp_routes` must be pre-rendered as `route1=<cidr>\nroute2=<cidr>…`.
  flake.modules.systemManager.host-ml-pf603jj8-openvpn-corp =
    { config, pkgs, lib, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        age.keyFile = "/home/juliendauliac/.config/sops/age/dotfiles.txt";
        defaultSopsFile = ../../secrets.yaml;

        secrets = {
          corp_ca = {
            sopsFile = ../home.juliendauliac/openvpn/ca.enc.crt;
            path = "/etc/openvpn/corp/ca.crt";
            mode = "0644";
            format = "binary";
          };
          corp_cert = {
            sopsFile = ../home.juliendauliac/openvpn/client.enc.crt;
            path = "/etc/openvpn/corp/corp.crt";
            mode = "0644";
            format = "binary";
          };
          corp_key = {
            sopsFile = ../home.juliendauliac/openvpn/client.enc.key;
            path = "/etc/openvpn/corp/corp.key";
            mode = "0600";
            format = "binary";
          };

          # AD login values + corp topology sourced from the root secrets.yaml.
          corp_email = { };
          corp_password = { };
          corp_remote = { };
          corp_uuid = { };
          # Pre-rendered as `route1=<cidr>\nroute2=<cidr>…` so it drops
          # straight into the [ipv4] section of the nmconnection file.
          corp_routes = { };
        };

        templates."corp.nmconnection" = {
          path = "/etc/NetworkManager/system-connections/corp.nmconnection";
          mode = "0600";
          owner = "root";
          content = ''
            [connection]
            id=corp
            uuid=${config.sops.placeholder.corp_uuid}
            type=vpn
            autoconnect=false
            autoconnect-retries=0

            [vpn]
            service-type=org.freedesktop.NetworkManager.openvpn
            connection-type=password-tls
            remote=${config.sops.placeholder.corp_remote}
            proto-tcp=no
            cipher=AES-256-GCM
            auth=SHA256
            ca=/etc/openvpn/corp/ca.crt
            cert=/etc/openvpn/corp/corp.crt
            key=/etc/openvpn/corp/corp.key
            remote-cert-tls=server
            dev=tun
            ping=10
            ping-restart=60
            reneg-seconds=0
            username=${config.sops.placeholder.corp_email}
            password-flags=0

            [vpn-secrets]
            password=${config.sops.placeholder.corp_password}

            [ipv4]
            method=auto
            never-default=true
            ignore-auto-routes=false
            ${config.sops.placeholder.corp_routes}

            [ipv6]
            method=ignore
          '';
        };
      };

      # After sops-nix drops the rendered keyfile at boot, tell NM to reload
      # so the new profile is picked up without a manual `nmcli con reload`.
      systemd.services.nm-reload-after-sops = {
        description = "Reload NetworkManager so the sops-rendered corp keyfile is picked up";
        wantedBy = [ "multi-user.target" ];
        after = [ "sops-nix.service" "NetworkManager.service" ];
        wants = [ "sops-nix.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.networkmanager}/bin/nmcli connection reload";
        };
      };
    };
}
