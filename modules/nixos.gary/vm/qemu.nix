{
  # qemu sizing for the VM sandbox.
  #
  # diskSize=8192: default is 1024 (1GB), which mkfs formats with only
  # 65k inodes.  Firefox exhausts inodes before touching any real-looking
  # disk cap and falls back to "missing or inaccessible profile" because
  # every new file write returns ENOSPC.  8GB gives ~500k inodes which is
  # plenty for a daily driver session.
  flake.modules.nixos.gary-vm-qemu = _: {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      graphics = true;
      diskSize = 8192;

      # Expose service ports to the host so the host browser can hit
      # http://localhost:<port> while the VM is running.  Also forwards
      # :80 so the gary-reverse-proxy landing page + vhost routing works
      # at http://sonarr.gary.local etc. (requires host /etc/hosts to map
      # *.gary.local -> 127.0.0.1; or just visit by port directly).
      # ssh (host 2222 -> guest 22) is already declared by the flake-level
      # vmModule in modules/flake/nixos-configurations.nix. Declaring it a
      # second time here produces a duplicate hostfwd rule and qemu refuses
      # to start ("Could not set up host forwarding rule 'tcp::2222-:22'").
      forwardPorts = [
        {
          from = "host";
          host.port = 8080;
          guest.port = 80;
        } # nginx (reverse-proxy)
        {
          from = "host";
          host.port = 3000;
          guest.port = 3000;
        } # adguard admin
        {
          from = "host";
          host.port = 8096;
          guest.port = 8096;
        } # jellyfin
        {
          from = "host";
          host.port = 5055;
          guest.port = 5055;
        } # jellyseerr
        {
          from = "host";
          host.port = 8989;
          guest.port = 8989;
        } # sonarr
        {
          from = "host";
          host.port = 7878;
          guest.port = 7878;
        } # radarr
        {
          from = "host";
          host.port = 8686;
          guest.port = 8686;
        } # lidarr
        {
          from = "host";
          host.port = 9696;
          guest.port = 9696;
        } # prowlarr
        {
          from = "host";
          host.port = 6767;
          guest.port = 6767;
        } # bazarr
        {
          from = "host";
          host.port = 8112;
          guest.port = 8112;
        } # qbittorrent
      ];
    };
  };
}
