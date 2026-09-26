{
  flake.modules.homeManager.desktop =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      nixProfileShare = "${config.home.profileDirectory}/share";
      localData = config.xdg.dataHome;
      manifestFile = "${localData}/applications/.nix-managed-desktops";
    in
    {
      home.packages = with pkgs; [
        gtk3
        desktop-file-utils
      ];

      home.activation.setupDesktopEntries = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        nixProfileApps="${nixProfileShare}/applications"
        localApps="${localData}/applications"
        manifest="${manifestFile}"

        run mkdir -p "$localApps"

        # Remove previously-installed nix-managed .desktop files
        if [ -f "$manifest" ]; then
          while IFS= read -r old; do
            if [ -f "$localApps/$old" ]; then
              run rm -f "$localApps/$old"
            fi
          done < "$manifest"
        fi

        # Copy current .desktop files and record them in the manifest
        : > "$manifest"
        if [ -d "$nixProfileApps" ]; then
          for src in "$nixProfileApps"/*.desktop; do
            [ -f "$src" ] || continue
            name="$(basename "$src")"
            run cp -fL "$src" "$localApps/$name"
            echo "$name" >> "$manifest"
          done
        fi

        # Rebuild desktop database so GNOME picks up new entries
        run ${pkgs.desktop-file-utils}/bin/update-desktop-database "$localApps"
      '';

      home.activation.setupDesktopIcons = lib.hm.dag.entryAfter [ "setupDesktopEntries" ] ''
        nixProfileIcons="${nixProfileShare}/icons"
        localIcons="${localData}/icons"

        # Sync every icon theme shipped by the nix profile (hicolor, Papirus, …)
        if [ -d "$nixProfileIcons" ]; then
          for themeDir in "$nixProfileIcons"/*/; do
            [ -d "$themeDir" ] || continue
            themeName="$(basename "$themeDir")"
            dst="$localIcons/$themeName"

            run mkdir -p "$dst"
            run chmod -R u+w "$dst" 2>/dev/null || true
            run ${pkgs.rsync}/bin/rsync -a --delete --copy-links "$themeDir" "$dst/"
            run chmod -R u+w "$dst"

            # Ensure index.theme exists (required by gtk-update-icon-cache)
            if [ ! -f "$dst/index.theme" ]; then
              if [ -f "/usr/share/icons/$themeName/index.theme" ]; then
                run cp "/usr/share/icons/$themeName/index.theme" "$dst/index.theme"
              fi
            fi

            # Build icon cache for fast lookups
            run ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t "$dst" || true
          done
        fi

        # Copy loose scalable/ directory if present (not inside a theme)
        if [ -d "$nixProfileIcons/scalable" ] && [ ! -d "$nixProfileIcons/scalable/index.theme" ]; then
          run mkdir -p "$localIcons/hicolor/scalable"
          run chmod -R u+w "$localIcons/hicolor/scalable" 2>/dev/null || true
          run ${pkgs.rsync}/bin/rsync -a --copy-links "$nixProfileIcons/scalable/" "$localIcons/hicolor/scalable/"
          run chmod -R u+w "$localIcons/hicolor/scalable"
        fi

        # Trigger GNOME Shell to rescan apps and icons (if a session bus exists)
        if [ -n "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
          # Re-set the icon-theme key to force GNOME to reload icon caches
          cur=$(${pkgs.dconf}/bin/dconf read /org/gnome/desktop/interface/icon-theme 2>/dev/null)
          if [ -n "$cur" ]; then
            ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/icon-theme "$cur" 2>/dev/null || true
          fi
        fi
        # Touch the applications dir to trigger GAppInfoMonitor inotify
        touch "${localData}/applications" 2>/dev/null || true
      '';
    };
}
