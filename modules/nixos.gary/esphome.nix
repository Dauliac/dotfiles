{
  flake.modules.nixos.gary-esphome =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (config.systemConstants) gary;
      esphomeSvc = gary.services.esphome;
    in
    lib.mkIf gary.featureFlags.esphome {
      services.esphome = {
        enable = true;
        address = "127.0.0.1"; # nginx fronts it via esphome.gary.local
        inherit (esphomeSvc) port;
        openFirewall = false; # LAN reachability is via reverse-proxy vhost only
      };
    };
}
