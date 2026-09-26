{ inputs, ... }:
{
  # NetBird client daemon on the Debian side.
  #
  # Rationale: system-manager only re-exports 8 upstream nixpkgs modules
  # (firewall, nginx, nix, openssh, programs, security, userborn,
  # users-groups) — `services.netbird` from NixOS proper is not available
  # under system-manager. So the daemon comes from NetBird's official
  # Debian repo (pkgs.netbird.io), wired through ansnix, exactly like we
  # already do for noctalia (see modules/system-manager.ML-PF603JJ8/default.nix
  # apt-repo + apt-packages roles).
  #
  # The tray (`netbird-ui`) is intentionally installed via apt too, not
  # via home-manager's `pkgs.netbird-ui`, because the .deb version links
  # against the same libayatana-appindicator the system already ships
  # and picks up Debian's gtk theme without an extra nixgl wrapper. The
  # HM side only owns the systemd user unit that starts it under niri —
  # see modules/home-manager/desktop/netbird-tray.nix.
  #
  # Config surface: the management URL is a confidential corp identifier
  # (sops key `corp_netbird_url` in the root secrets.yaml), so we feed it
  # to the daemon via a sops-rendered EnvironmentFile — not a plaintext
  # drop-in with a hardcoded URL, and not a hand-seeded config.json.
  # Chain:
  #   sops.templates."netbird.env"      → /run/secrets/rendered/netbird.env
  #     ↓ (contains NB_MANAGEMENT_URL=… + NB_ADMIN_URL=… on two lines)
  #   systemd drop-in on netbird.service → EnvironmentFile=<that path>
  #     ↓
  #   NetBird daemon reads NB_MANAGEMENT_URL at first start, generates
  #   the full profile itself at /var/lib/netbird/default.json.
  #
  # Earlier attempts:
  # - Seeded /etc/netbird/config.json with just `{ ManagementURL, AdminURL }`
  #   → daemon crash-looped because its profile-manager expects the *full*
  #   config shape (PrivateKey, WgIface, RoutesToDelete, …) and rejected
  #   the partial file.
  # - Plaintext Environment= drop-in with the URL literal → leaks corp
  #   identifier into the flake / nix store world-readably.
  #
  # sops-rendered EnvironmentFile keeps the URL out of the store, gives
  # systemd a normal env-var handoff, and survives apt package upgrades
  # (the drop-in lives outside /lib/systemd/system/ so apt can't touch it).
  # NetBird's client/cmd/root.go accepts NB_MANAGEMENT_URL / NB_ADMIN_URL
  # as env fallbacks for --management-url / --admin-url.
  #
  # First-join is still interactive SSO in the browser; NetBird persists
  # the JWT alongside the profile at /var/lib/netbird/default.json.
  #
  # If Manomano ever changes the management URL:
  #   sops set secrets.yaml '["corp_netbird_url"]' '"https://new.corp.tech:443"'
  #   sudo rm -f /var/lib/netbird/default.json
  #   xi -e sudo system switch
  #   sudo systemctl restart netbird && sudo netbird up
  #
  # NOTE: The apt-repo + apt-packages entries for netbird / netbird-ui
  # live in modules/system-manager.ML-PF603JJ8/default.nix alongside the
  # existing `danklinux` / `noctalia` entries. ansnix.roles.apt-repo.repos
  # and .apt-packages.packages are plain `listOf submodule` in the ansnix
  # schema, so the module system does not auto-merge two separate
  # definitions from different modules — every host that wants extra
  # apt repos/packages must colocate them in that single list. This
  # module therefore only owns the sops wiring + systemd drop-in.
  flake.modules.systemManager.host-ml-pf603jj8-netbird =
    { config, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        # age keyFile + defaultSopsFile are already set by the sibling
        # openvpn-corp module in this host; sops-nix merges these attrs
        # across module instances, so re-declaring them here would just be
        # duplication. The template + secret below inherit both.
        secrets.corp_netbird_url = { };

        templates."netbird.env" = {
          # /run/secrets/rendered/<name> by default; systemd needs a
          # concrete path to point EnvironmentFile at.
          path = "/run/secrets/rendered/netbird.env";
          mode = "0400";
          owner = "root";
          # Two lines so both env vars land. NetBird's daemon uses AdminURL
          # for its dashboard link in the tray; we point it at the same URL
          # since the corp instance colocates both.
          content = ''
            NB_MANAGEMENT_URL=${config.sops.placeholder.corp_netbird_url}
            NB_ADMIN_URL=${config.sops.placeholder.corp_netbird_url}
          '';
        };
      };

      # Systemd drop-in on netbird.service — loads the sops-rendered env
      # file AND makes netbird wait for sops-nix to finish rendering it.
      # Without the After=/Wants= guards, boot races between sops-nix.service
      # (which writes /run/secrets/rendered/netbird.env) and netbird.service
      # (which reads it) can leave the daemon starting with an empty
      # EnvironmentFile and crash-looping. Mirror the openvpn-corp module's
      # nm-reload-after-sops pattern.
      environment.etc."systemd/system/netbird.service.d/50-management-url.conf".text = ''
        [Unit]
        After=sops-nix.service
        Wants=sops-nix.service

        [Service]
        EnvironmentFile=/run/secrets/rendered/netbird.env
      '';
    };
}
