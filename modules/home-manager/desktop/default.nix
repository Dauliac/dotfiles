# Desktop configuration - auto-imported by import-tree
# No imports needed - other desktop modules are automatically discovered
{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (
      {
        pkgs,
        config,
        lib,
        ...
      }:
      {
        # Ensure the tools are available
        home.packages = with pkgs; [
          gtk3 # provides gtk-update-icon-cache
          desktop-file-utils # provides update-desktop-database
        ];

        # Copy icons from nix-profile to ~/.local/share/icons for GNOME
        # This is necessary because:
        # 1. Nix store is read-only, so we can't create icon-theme.cache there
        # 2. GNOME needs the cache file to display icons properly
        home.activation.setupDesktopIcons = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          nixProfileIcons="${config.home.profileDirectory}/share/icons/hicolor"
          localIcons="${config.xdg.dataHome}/icons/hicolor"

          if [ -d "$nixProfileIcons" ]; then
            # Use rsync-like copy: only copy newer files, preserve structure
            run mkdir -p "$localIcons"

            # Copy icon files from nix-profile to local icons dir
            # Use cp with dereference to resolve symlinks
            run ${pkgs.rsync}/bin/rsync -a --delete --copy-links "$nixProfileIcons/" "$localIcons/"

            # Update icon cache (now in a writable location)
            if command -v gtk-update-icon-cache &> /dev/null; then
              run gtk-update-icon-cache -f "$localIcons" 2>/dev/null || true
            fi
          fi

          # Update desktop database
          if command -v update-desktop-database &> /dev/null; then
            localApps="${config.xdg.dataHome}/applications"
            run mkdir -p "$localApps"
            run update-desktop-database "$localApps" 2>/dev/null || true
          fi
        '';
      }
    )
  ];
}
