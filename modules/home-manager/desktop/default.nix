{
  flake.modules.homeManager.desktop =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        gtk3
        desktop-file-utils
      ];

      home.activation.setupDesktopIcons = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        nixProfileIcons="${config.home.profileDirectory}/share/icons/hicolor"
        localIcons="${config.xdg.dataHome}/icons/hicolor"

        if [ -d "$nixProfileIcons" ]; then
          run mkdir -p "$localIcons"
          run ${pkgs.rsync}/bin/rsync -a --delete --copy-links "$nixProfileIcons/" "$localIcons/"

          if command -v gtk-update-icon-cache &> /dev/null; then
            run gtk-update-icon-cache -f "$localIcons" 2>/dev/null || true
          fi
        fi

        if command -v update-desktop-database &> /dev/null; then
          localApps="${config.xdg.dataHome}/applications"
          run mkdir -p "$localApps"
          run update-desktop-database "$localApps" 2>/dev/null || true
        fi
      '';
    };
}
