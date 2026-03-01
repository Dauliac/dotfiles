{ config, ... }:
let
  cfg = config;
in
{
  config.perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      packages = {
        # Nix wrapper with better alternatives
        inherit (pkgs) nx;
        inherit (pkgs) neix;

        # Build all flake outputs using devour-flake with nix-output-monitor
        # Usage: nix run .#build-all
        build-all = pkgs.writeShellApplication {
          name = "build-all";
          runtimeInputs = with pkgs; [
            nix
            jq
            nix-output-monitor
            config.flake-root.package
          ];
          text = ''
            set -euo pipefail
            FLAKE_ROOT="$(flake-root)"
            echo "Building all flake outputs from: $FLAKE_ROOT"
            echo ""

            # Use devour-flake with nix-output-monitor for nice TUI
            # nom outputs TUI to stderr, so we capture stdout separately
            RESULT=$(nom build github:srid/devour-flake#default \
              --override-input flake "path:$FLAKE_ROOT" \
              --no-link --print-out-paths)

            echo ""
            echo "Build complete! Output manifest: $RESULT"
            echo ""
            echo "Built outputs:"
            jq -r 'to_entries[] | "\(.key):\n  \(.value.byName | keys | join(", "))"' "$RESULT"
          '';
        };

        # CI script (no TUI, verbose logging)
        ci = pkgs.writeShellApplication {
          name = "ci-build-all";
          runtimeInputs = with pkgs; [
            nix
            jq
            config.flake-root.package
          ];
          text = ''
            set -euo pipefail
            FLAKE_ROOT="$(flake-root)"
            echo "=== CI Build All ==="
            echo "Building all flake outputs from: $FLAKE_ROOT"
            echo ""

            nix build github:srid/devour-flake#default \
              --override-input flake "path:$FLAKE_ROOT" \
              -L --no-link --print-out-paths "$@"
          '';
        };

        nixos = pkgs.stdenv.mkDerivation {
          name = "nixos-system";
          buildCommand = ''
            cp -r ${cfg.flake.nixosConfigurations.spongebob.config.system.build.toplevel} $out
          '';
        };
        homeManagerJulienDauliac = pkgs.stdenv.mkDerivation {
          name = "home-manager-system";
          buildCommand = ''
            cp -r ${builtins.head cfg.flake.homeConfigurations.juliendauliac.activation-script.all} $out
          '';
        };
        homeManagerDauliac = pkgs.stdenv.mkDerivation {
          name = "home-manager-system";
          buildCommand = ''
            cp -r ${builtins.head cfg.flake.homeConfigurations.dauliac.activation-script.all} $out
          '';
        };
        systemML-PF59GCGW = pkgs.stdenv.mkDerivation {
          name = "home-manager-system";
          buildCommand = ''
            cp -r ${builtins.head cfg.flake.systemConfigs.ML-PF59GCGW.config.build.toplevel.all} $out
          '';
        };
        default = config.packages.nixos;
      };
    };
}
