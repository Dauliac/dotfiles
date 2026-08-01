{ inputs, ... }:
let
  xdgConfigDir = ./xdg-config;
in
{
  flake.modules.homeManager.base = { config, ... }: {
    imports = [
      inputs.self.modules.generic.shell
      inputs.nix-index-db.homeModules.nix-index
      inputs.sops-nix.homeManagerModules.sops
      inputs.catppuccin.homeModules.catppuccin
      inputs.stylix.homeModules.stylix
      inputs.nixvim.homeModules.nixvim
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      inputs.betterfox-nix.modules.homeManager.betterfox
      inputs.noctalia.homeModules.default
      inputs.mcps.homeManagerModules.claude
    ];

    home.stateVersion = "25.05";
    home.enableNixpkgsReleaseCheck = false;
    home.file."${config.xdg.configHome}" = {
      source = xdgConfigDir;
      recursive = true;
    };
    fonts.fontconfig.enable = true;
    xdg.enable = true;
    xdg.mime.enable = true;
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/https" = "app.zen_browser.zen.desktop";
      "text/html" = "app.zen_browser.zen.desktop";
      "application/xhtml+xml" = "app.zen_browser.zen.desktop";
    };
    xdg.configFile."mimeapps.list".force = true;
    xdg.systemDirs.data = [
      "${config.home.profileDirectory}/share"
      "/nix/var/nix/profiles/default/share"
    ];
    home.sessionVariables = {
      BROWSER = "zen";
    };

    # Ensure GNOME (and other graphical sessions) can find nix binaries
    # and .desktop files.  Ubuntu's /usr/lib/environment.d/990-snapd.conf
    # also sets PATH and XDG_DATA_DIRS; per environment.d(5) "the entry in
    # the file with the lexicographically latest name will be applied", so
    # our file must sort AFTER 990-*.  Using 999- guarantees that.
    xdg.configFile."environment.d/999-nix-session.conf".text =
      let
        xdgDataDirs = builtins.concatStringsSep ":" config.xdg.systemDirs.data;
      in
      ''
        PATH=${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin''${PATH:+:$PATH}
        XDG_DATA_DIRS=${xdgDataDirs}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}
      '';
  };
}
