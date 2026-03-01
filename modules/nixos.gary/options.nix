# Shared options for gary host
# Only defines common/cross-cutting options
# Service-specific options are defined in their respective modules
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.dotfiles.gary = {
    network = {
      lanIP = mkOption {
        type = types.str;
        default = "192.168.1.100";
        description = "Gary's LAN IP address";
      };

      interface = mkOption {
        type = types.str;
        default = "eth0";
        description = "Primary network interface";
      };

      gateway = mkOption {
        type = types.str;
        default = "192.168.1.1";
        description = "Default gateway / router IP";
      };
    };

    domain = {
      public = mkOption {
        type = types.str;
        default = "j4rd1.cloud";
        description = "Public domain name";
      };

      local = mkOption {
        type = types.str;
        default = "gary.local";
        description = "Local domain name for LAN access";
      };
    };

    media = {
      dataDir = mkOption {
        type = types.path;
        default = "/data/media";
        description = "Media storage directory";
      };

      stateDir = mkOption {
        type = types.path;
        default = "/data/.state";
        description = "State/config storage directory";
      };
    };
  };
}
