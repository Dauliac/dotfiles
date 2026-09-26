{
  # Everything a niri session needs but that niri itself does not ship:
  #   - polkit agent (mount, network, updates auth prompts)
  #   - XWayland bridge (systemd user unit; niri does not ship one)
  #   - xdg-desktop-portal backend preference (portal daemons themselves are
  #     wired by niri-flake)
  #   - TTY1 auto-launch for the "no login manager" flow
  #   - the userspace wayland toolbox: clipboard, screenshot, brightness,
  #     idle, session dialog, PipeWire volume
  #
  # Lockscreen is handled by noctalia (see
  # modules/home-manager/desktop/noctalia/default.nix): it listens on
  # logind's Lock signal via its `[logind] session lock monitor`, so we
  # trigger the lock indirectly via `loginctl lock-session` from swayidle
  # + the Super+Shift+L bind. That keeps this module lockscreen-agnostic.
  flake.modules.homeManager.niri =
    { pkgs, config, ... }:
    let
      # When niri is distro-managed ("system"), pin the autostart to the
      # Debian-installed /usr/bin/niri-session so we run the same binary
      # that the distro's mesa userspace was built for. Otherwise fall
      # back to `command -v niri-session`, which resolves to the
      # nixpkgs one.
      niriSessionCmd =
        if config.systemConstants.nixgl.wrapperType == "system" then
          "/usr/bin/niri-session"
        else
          "niri-session";
      ttyAutostart = ''
        # niri autostart from tty1 — no display manager.
        # _NIRI_AUTOSTART_TRIED guard breaks an infinite exec loop: Debian's
        # /usr/bin/niri-session re-execs the user's shell as a login shell to
        # inherit the login environment, which re-sources this .zprofile which
        # would exec niri-session again → forever. Exec preserves env, so the
        # sentinel survives across the re-exec and short-circuits the second
        # trigger. niri-session itself calls `systemctl --user unset-environment`
        # on shutdown, so the guard clears cleanly for the next tty1 login.
        if [ -z "''${WAYLAND_DISPLAY:-}" ] \
          && [ -z "''${_NIRI_AUTOSTART_TRIED:-}" ] \
          && { [ "''${XDG_VTNR:-}" = "1" ] || [ "$(tty 2>/dev/null)" = "/dev/tty1" ]; } \
          && command -v ${niriSessionCmd} >/dev/null 2>&1; then
          export _NIRI_AUTOSTART_TRIED=1
          exec ${niriSessionCmd}
        fi
      '';
    in
    {
      # ── xdg-desktop-portal backend preference ────────────────────────────
      # niri-flake registers the portal services; we only pick a backend.
      # gtk covers everything except Screencast/ScreenCast which niri handles
      # natively through xdg-desktop-portal-gnome if present; leave gnome-keyring
      # for the Secret portal.
      xdg.configFile."xdg-desktop-portal/niri-portals.conf".text = ''
        [preferred]
        default=gnome;gtk
        org.freedesktop.impl.portal.Secret=gnome-keyring
      '';

      # ── Default apps (xdg-mime handlers) ─────────────────────────────────
      # HM base already sets http/https/html/xhtml → zen. Everything else
      # lands here so it only registers when the niri session (and its
      # handler apps) are installed. Merged with the base attrset by Nix.
      xdg.mimeApps.defaultApplications = {
        "x-scheme-handler/mailto" = "app.zen_browser.zen.desktop";
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "audio/mpeg" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/ogg" = "mpv.desktop";
        "application/pdf" = "org.pwmt.zathura.desktop";
        "inode/directory" = "yazi.desktop";
        "text/plain" = "nvim.desktop";
        "application/zip" = "org.gnome.FileRoller.desktop";
        "application/x-tar" = "org.gnome.FileRoller.desktop";
        "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
        "application/gzip" = "org.gnome.FileRoller.desktop";
      };

      # ── udiskie — USB auto-mount ─────────────────────────────────────────
      # No tray icon (noctalia handles that layer). Notifications ON so
      # a plug event is visible even without opening a file manager.
      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "never";
      };

      # ── swayidle — auto-lock + DPMS off ──────────────────────────────────
      # 5min → lock, 10min → screens off, sleep → lock.
      # The lock trigger is `loginctl lock-session`, which fires logind's
      # Lock signal on the user's session; noctalia's logind session lock
      # monitor picks it up and shows the lock screen. Keeping swayidle
      # here (rather than moving idle handling into noctalia's [idle]
      # config) so the niri-specific DPMS commands stay in one place.
      #
      # The `lock` event handler is intentionally omitted: swayidle's
      # `lock` fires when someone else calls `loginctl lock-session`, and
      # that same call already reaches noctalia through logind — running
      # `loginctl lock-session` again in response would be redundant.
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 300;
            command = "${pkgs.systemd}/bin/loginctl lock-session";
          }
          {
            timeout = 600;
            command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
            resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
          }
        ];
        events = [
          {
            event = "before-sleep";
            command = "${pkgs.systemd}/bin/loginctl lock-session";
          }
        ];
      };

      # ── cliphist watcher — populate clipboard history ────────────────────
      # Picker is noctalia (launcher IPC). Until a first-party clipboard-
      # history plugin lands upstream, `cliphist list | cliphist decode |
      # wl-copy` from a shell works as a fallback.
      systemd.user.services.cliphist = {
        Unit = {
          Description = "cliphist — clipboard history watcher";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # ── TTY1 auto-launch ─────────────────────────────────────────────────
      # No display manager on ML-PF59GCGW; on tty1 login the shell exec's
      # niri-session which sets up the wayland env, dbus activation, and
      # graphical-session.target.
      programs.zsh.profileExtra = ttyAutostart;
      programs.bash.profileExtra = ttyAutostart;

      # ── gnome-keyring (Secret portal + SSH agent) ────────────────────────
      # portals.conf above routes org.freedesktop.impl.portal.Secret to
      # gnome-keyring, but nothing was starting the daemon under niri.
      # Without it, Signal/Slack/gh silently fall back to plaintext.
      # `ssh` component publishes the SSH_AUTH_SOCK the ASKPASS wiring uses.
      services.gnome-keyring = {
        enable = true;
        components = [ "pkcs11" "secrets" "ssh" ];
      };

      # ── sudo / ssh askpass ───────────────────────────────────────────────
      # seahorse ships ssh-askpass at libexec/seahorse/ssh-askpass. Both env
      # vars point at it so GUI-launched processes (from noctalia launcher,
      # systemd user units, or the compositor spawn action) can prompt.
      home.sessionVariables = {
        SUDO_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
        SSH_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
        # Force GUI helper even when a TTY is attached (systemd user
        # unit case); default is "prefer" which uses the TTY prompt.
        SSH_ASKPASS_REQUIRE = "prefer";
      };

      # ── polkit authentication agent ──────────────────────────────────────
      systemd.user.services.polkit-gnome-authentication-agent-1 = {
        Unit = {
          Description = "polkit-gnome authentication agent";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # ── XWayland bridge (headless XWayland instance for X11 apps) ────────
      systemd.user.services.xwayland-satellite = {
        Unit = {
          Description = "XWayland outside your Wayland compositor";
          BindsTo = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "notify";
          NotifyAccess = "all";
          ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # ── Session toolbox ──────────────────────────────────────────────────
      home.packages = with pkgs; [
        # Idle daemon + logout menu. Lockscreen is noctalia (apt-installed
        # on system-manager hosts); swayidle triggers it via loginctl.
        swayidle
        wlogout

        # Wallpaper is drawn by noctalia itself (see
        # modules/home-manager/desktop/noctalia/wallpaper.nix); no external
        # daemon needed. Use `noctalia msg wallpaper-{get,set,next,random}`.

        # XDG portal backends (niri-flake wires the daemons)
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        # -wlr is the fallback some Flatpak apps look for (screencast on
        # wlroots-based compositors). -gnome covers screencast on niri
        # already, but adding -wlr closes a Flatpak-app-compat gap.
        xdg-desktop-portal-wlr

        # Clipboard
        wl-clipboard
        cliphist

        # Screenshot / region select
        grim
        slurp

        # Media & hardware controls
        playerctl
        brightnessctl
        pamixer

        # XWayland bridge binary (systemd unit above references it)
        xwayland-satellite

        # polkit agent binary (systemd unit above references it)
        polkit_gnome

        # Secret Service consumers (Signal / Slack / gh / vscode) load
        # libsecret at runtime. Without it in profile they silently fall
        # back to plaintext or an in-memory keyring that dies with the app.
        libsecret

        # ssh-askpass provider referenced by SUDO_ASKPASS / SSH_ASKPASS
        # env vars above; also gives you a graphical keyring browser.
        seahorse

        # ── Default-app handlers (registered by mimeApps above) ──────────
        imv           # image viewer
        mpv           # audio + video player
        zathura       # PDF reader
        file-roller   # archive manager
        # yazi + neovim already installed via their own modules.

        # ── gvfs — network mounts (smb, sftp, nfs), MTP, trash, ── ───────
        # On NixOS `services.gvfs.enable = true;` is preferred (registers
        # system-wide D-Bus service). Installing the package here works
        # per-user on Debian (juliendauliac) too — HM's xdg.systemDirs.data
        # exposes the profile's dbus service files to the user session bus.
        gvfs

        # ── QoL: screenshot annotator + color picker + recorder + pickers ─
        satty              # bound to Shift+Print in binds.nix
        hyprpicker         # bound to Mod+Shift+C
        wf-recorder        # user launches manually: `wf-recorder -g "$(slurp)"`
        wl-clip-persist    # keeps clipboard alive when the source app quits
                           # (systemd user service below)

        # ── QoL: tray applets for network + bluetooth ─────────────────────
        # noctalia's tray widget shows their icons if these daemons run.
        # Without them the tray widget is empty for NM / bluez.
        networkmanagerapplet
        blueman
      ];

      # wl-clip-persist as a user service so clipboard survives short-lived
      # apps like screenshot tools, one-shot pipes, etc.
      systemd.user.services.wl-clip-persist = {
        Unit = {
          Description = "wl-clip-persist — keep clipboard alive after source dies";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # ── Qt platform theme (Q9) ────────────────────────────────────────────
      # dbeaver, pavucontrol-qt, moonlight-qt, ... without this render with
      # default Qt style; with this they follow GTK theme (stylix / catppuccin).
      #
      # Disable stylix's qt target so we can own qt.style/qt.platformTheme
      # without tripping its "Changing config.qt.style is unsupported" warning.
      # Stylix's qt module defaults platformTheme.name to "qtct" and style to
      # "kvantum"; we want Qt to follow the GTK theme under the niri/GNOME-
      # portal session instead.
      stylix.targets.qt.enable = false;
      qt = {
        enable = true;
        platformTheme.name = "gtk";
        style.name = "adwaita-dark";
      };
    };
}
