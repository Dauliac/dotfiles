_: {
  flake.modules.generic.nixgl-wrapper =
    {
      lib,
      config,
      ...
    }:
    {
      options.systemConstants.nixgl = {
        wrapperType = lib.mkOption {
          type = lib.types.enum [
            "auto"
            "intel"
            "nvidia"
            "mesa"
            "none"
          ];
          default = "none";
          description = ''
            Which nixGL wrapper to use for GPU acceleration on non-NixOS systems.
            "none" on NixOS systems where it's not needed.
            "auto" for runtime detection (slower startup).
            Otherwise a specific driver for better performance.
          '';
        };

        wrapPackage = lib.mkOption {
          type = lib.types.unspecified;
          description = ''
            Wraps a package with nixGL for GPU acceleration.
            Type: { pkgs, wrapperType? } -> package -> package
          '';
          default =
            {
              pkgs,
              wrapperType ? config.systemConstants.nixgl.wrapperType,
            }:
            pkg:
            let
              nixGL =
                if wrapperType == "auto" then
                  pkgs.nixgl.auto.nixGLDefault
                else if wrapperType == "intel" then
                  pkgs.nixgl.nixGLIntel
                else if wrapperType == "nvidia" then
                  pkgs.nixgl.nixGLNvidia
                else if wrapperType == "mesa" then
                  pkgs.nixgl.nixGLMesa
                else
                  null;

              nixGLBin =
                if wrapperType == "auto" then
                  "nixGL"
                else if wrapperType == "intel" then
                  "nixGLIntel"
                else if wrapperType == "nvidia" then
                  "nixGLNvidia"
                else if wrapperType == "mesa" then
                  "nixGLMesa"
                else
                  null;

              binaries = builtins.filter (
                name: !lib.hasPrefix "." name && name != ".${pkg.pname or pkg.name}-wrapped"
              ) (builtins.attrNames (builtins.readDir "${pkg}/bin"));
            in
            if nixGL == null || wrapperType == "none" then
              pkg
            else
              pkgs.symlinkJoin {
                name = "nixGL-${pkg.name}";
                paths = [ pkg ];
                nativeBuildInputs = [ pkgs.makeWrapper ];
                postBuild = ''
                  # Wrap each binary with nixGL
                  for bin in ${builtins.concatStringsSep " " binaries}; do
                    rm -f "$out/bin/$bin"
                    makeWrapper "${nixGL}/bin/${nixGLBin}" "$out/bin/$bin" \
                      --add-flags "${pkg}/bin/$bin"
                  done

                  # Patch systemd service files to use wrapped binary
                  if [ -d "$out/share/systemd/user" ]; then
                    for f in "$out/share/systemd/user"/*.service; do
                      if [ -f "$f" ]; then
                        rm -f "$f"
                        sed "s|${pkg}/bin/|$out/bin/|g" "${pkg}/share/systemd/user/$(basename "$f")" > "$f"
                      fi
                    done
                  fi

                  # Patch dbus service files
                  if [ -d "$out/share/dbus-1/services" ]; then
                    for f in "$out/share/dbus-1/services"/*.service; do
                      if [ -f "$f" ]; then
                        rm -f "$f"
                        sed "s|${pkg}/bin/|$out/bin/|g" "${pkg}/share/dbus-1/services/$(basename "$f")" > "$f"
                      fi
                    done
                  fi

                  # Patch desktop files
                  if [ -d "$out/share/applications" ]; then
                    for f in "$out/share/applications"/*.desktop; do
                      if [ -f "$f" ]; then
                        rm -f "$f"
                        sed "s|${pkg}/bin/|$out/bin/|g" "${pkg}/share/applications/$(basename "$f")" > "$f"
                      fi
                    done
                  fi
                '';
              };
        };
      };
    };
}
