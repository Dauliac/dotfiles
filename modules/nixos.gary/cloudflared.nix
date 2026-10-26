{
  # Dashboard-managed Cloudflare Tunnel ("ray-lovers-club"). Ingress rules
  # and Access policies live in the Cloudflare dashboard, not here, so the
  # nix side is just a long-running `cloudflared tunnel run` fed by a
  # connect token from sops-nix.
  #
  # Upstream services.cloudflared only supports locally-managed tunnels
  # (credentials-file + in-nix ingress), so we drive our own systemd unit.
  flake.modules.nixos.gary-cloudflared =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.systemConstants.gary.featureFlags.cloudflared {
      systemd.services.cloudflared = {
        description = "Cloudflare Tunnel (ray-lovers-club)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel --metrics 127.0.0.1:60123 run";
          EnvironmentFile = config.sops.templates."cloudflared-tunnel.env".path;
          Restart = "on-failure";
          RestartSec = "5s";
          DynamicUser = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          NoNewPrivileges = true;
          PrivateTmp = true;
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        };
      };
    };
}
