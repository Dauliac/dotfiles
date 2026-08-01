{
  flake.modules.nixos.gary-matter-server =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (config.systemConstants) gary;
    in
    lib.mkIf gary.featureFlags.matterServer {
      services.matter-server = {
        enable = true;
        # Home Assistant connects via ws://127.0.0.1:5580/ws — the HA "Matter Server"
        # integration is added via services.home-assistant.extraComponents = [ "matter" ].
      };

      # Matter uses IPv6 mDNS on the LAN — avahi is already enabled by
      # gary-home-assistant, so no extra networking required.
    };
}
