# Firefox configuration for gary
# Split into separate files for each concern
{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  # ════════════════════════════════════════════
  # OPTIONS
  # ════════════════════════════════════════════
  options.dotfiles.gary.firefox = {
    enable = mkEnableOption "Firefox browser";

    # Local services for bookmarks (passed from NixOS)
    localServices = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
          };
          subdomain = mkOption {
            type = types.str;
          };
          description = mkOption {
            type = types.str;
            default = "";
          };
          port = mkOption {
            type = types.port;
          };
        };
      });
      default = { };
      description = "Local services to add as bookmarks";
    };

    domain = mkOption {
      type = types.str;
      default = "gary.local";
      description = "Domain for local service bookmarks";
    };

    useTLS = mkOption {
      type = types.bool;
      default = false;
      description = "Use HTTPS for local service bookmarks";
    };

    scale = mkOption {
      type = types.str;
      default = "1";
      description = "UI scale factor (devPixelsPerPx)";
    };
  };

  # ════════════════════════════════════════════
  # IMPLEMENTATION
  # ════════════════════════════════════════════
  config.dotfiles.home.userModules.gary = lib.mkAfter [
    (
      { config, ... }:
      let
        cfg = config.dotfiles.gary.firefox;
      in
      lib.mkIf cfg.enable {
        programs.firefox.enable = true;
        programs.firefox.betterfox.enable = true;
      }
    )
  ];
}
