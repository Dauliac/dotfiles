{
  # VM-only arr stack bringup.  Rather than instantiate kiriwalawren/nixflix
  # (which needs real sops secrets + /data/media mount + declarative api
  # keys), the VM runs each arr service directly from nixpkgs with its
  # built-in first-boot bootstrapping.  Each service generates its own
  # api key on first start and writes it to its state dir; nginx proxies
  # <svc>.gary.local -> 127.0.0.1:<port> via gary-reverse-proxy.
  #
  # Goal: confirm the networking + reverse-proxy topology end-to-end from
  # the host browser.  Inter-service wiring (prowlarr->arrs, seerr->jellyfin)
  # is OUT of scope here; that's the point of running real gary with full
  # nixflix declaration.
  flake.modules.nixos.gary-vm-arr =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (config.systemConstants) gary;
    in
    lib.mkIf (gary.featureFlags.vmArrStack or false) {
      # Writable scratch for media libs - replaces real gary's /data mount.
      systemd.tmpfiles.rules = [
        "d /var/lib/vm-media 0775 root users -"
        "d /var/lib/vm-media/tv 0775 root users -"
        "d /var/lib/vm-media/movies 0775 root users -"
        "d /var/lib/vm-media/music 0775 root users -"
      ];

      services.sonarr = {
        enable = true;
        openFirewall = true;
      };
      services.radarr = {
        enable = true;
        openFirewall = true;
      };
      services.lidarr = {
        enable = true;
        openFirewall = true;
      };
      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };
      services.bazarr = {
        enable = true;
        openFirewall = true;
      };
      services.jellyfin = {
        enable = true;
        openFirewall = true;
      };
      services.seerr = {
        enable = true;
        openFirewall = true;
      };
      services.qbittorrent = {
        enable = true;
        openFirewall = true;
        # nixpkgs default is 8080 which clashes with the qemu host->guest
        # port forward for nginx (host:8080 -> guest:80).  Match the gary
        # service catalog's 8112 entry instead.
        webuiPort = 8112;
      };
    };
}
