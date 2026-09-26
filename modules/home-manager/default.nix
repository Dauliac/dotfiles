{ inputs, ... }:
let
  xdgConfigDir = ./xdg-config;
in
{
  flake.modules.homeManager.base = { config, lib, pkgs, ... }: {
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
      # xdg-open defers to xdg.mimeApps.defaultApplications above (zen for
      # http/https/html), so this respects whatever the mime handler says.
      # Was `zen` — broken because zen ships as Flatpak with binary name
      # `app.zen_browser.zen`, not `zen`.
      BROWSER = "xdg-open";
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

    # Flatpak update policy (applies to every HM user who opts into
    # services.flatpak.enable — currently juliendauliac and gary).
    # mkDefault so a per-user config can flip it off.
    services.flatpak.update.onActivation = lib.mkDefault true;

    # Weekly per-user background update. Catches long stretches without
    # a `xi home switch` (juliendauliac laptop in particular).
    systemd.user.services.flatpak-update = lib.mkIf config.services.flatpak.enable {
      Unit.Description = "Update flatpak apps (weekly)";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.flatpak}/bin/flatpak --user update --noninteractive --assumeyes";
      };
    };
    systemd.user.timers.flatpak-update = lib.mkIf config.services.flatpak.enable {
      Unit.Description = "Weekly flatpak update timer";
      Install.WantedBy = [ "timers.target" ];
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
