{ inputs, ... }: {
  # ML-PF603JJ8 — successor laptop to ML-PF59GCGW. Config kept in sync with
  # its predecessor for now; diverge here when hardware/policy differs
  # (e.g. cpu.count if the new machine has a different core count).
  #
  # Debian-side bootstrap (apt packages, PAM edits, default systemd target)
  # is declared via `ansnix = { … };` below and executed by the
  # `ansnix` module (github:Dauliac/ansnix),
  # which composes disk-backed roles into a single systemd oneshot playbook.
  # Everything else — including flatpak apps, keyboard layout, niri config —
  # is declared elsewhere in this flake.
  flake.modules.systemManager.host-ml-pf603jj8 =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.aws-nix-cache.systemManagerModules.default
        inputs.self.modules.systemManager.nix-throttle
        # Declarative Debian bootstrap: apt installs + PAM edits via ansible.
        inputs.ansnix.systemManagerModules.default
        # Corp OpenVPN — sops-nix decrypts certs + NM keyfile at activation.
        inputs.self.modules.systemManager.host-ml-pf603jj8-openvpn-corp
        # Docker daemon (socket-activated, userborn-managed docker group).
        inputs.self.modules.systemManager.docker
        # ScreenCast portal backend for niri (Vesktop / browser screenshare).
        inputs.self.modules.systemManager.screen-share
        # Register the nix-managed zsh in /etc/shells so pam_shells accepts it.
        inputs.self.modules.systemManager.login-shells
        # Backfill /etc/pam.d/polkit-1 so pkexec authentication works
        # (xi system switch → pkexec → polkit-agent-helper-1 → PAM stack).
        inputs.self.modules.systemManager.polkit
        # unattended-upgrades: security-origin only, status broadcast to
        # noctalia via notify-send + /run/auto-upgrade/latest.json.
        # Uses `system.autoUpgrade` (nixpkgs-shaped option surface).
        inputs.self.modules.systemManager.auto-upgrade
        # NetBird client — apt-installed daemon + tray from pkgs.netbird.io,
        # ManagementURL seeded into /etc/netbird/config.json for first-join
        # SSO. Tray unit lives under HM (netbird-tray).
        inputs.self.modules.systemManager.host-ml-pf603jj8-netbird
      ];

      # Opt in to the ansnix backend of system.autoUpgrade.
      # See modules/system-manager/auto-upgrade.nix for honored fields.
      system.autoUpgrade = {
        enable = true;
        # backend = "ansnix";  # default
        dates = "04:40";
        randomizedDelaySec = "45min";
        persistent = true;
        allowReboot = false;
      };


      # Debian-side declarative bootstrap.
      # Docker group membership is handled by users.groups.docker.members below
      # (via userborn), so we omit the user-in-group role.
      ansnix = {
        enable = true;

        roles = {
          systemd-default-target = {
            priority = 50;
            # graphical.target so greetd.service (WantedBy=graphical.target)
            # comes up at boot on tty1. The prior "multi-user" left the box on
            # a bare console, and the shell-autostart path from tty1 login
            # infinite-looped through Debian's niri-session re-exec dance —
            # see modules/home-manager/desktop/niri/session.nix and the
            # _NIRI_AUTOSTART_TRIED guard for that story.
            target = "graphical";
          };

          apt-repo = {
            priority = 60;
            repos = [
              {
                name = "danklinux";
                url = "https://download.opensuse.org/repositories/home:AvengeMedia:danklinux/Debian_13";
                keyUrl = "https://download.opensuse.org/repositories/home:AvengeMedia:danklinux/Debian_13/Release.key";
              }
              # noctalia (Wayland shell + lockscreen). Nix-built noctalia
              # links against a libpam that cannot parse Debian's @include
              # PAM syntax, so the lock screen rejects every password with
              # PAM_PERM_DENIED. Installing via the upstream Debian repo
              # gives us a binary linked to Debian's libpam, which parses
              # /etc/pam.d/login correctly. See
              # modules/home-manager/desktop/noctalia/default.nix for the
              # HM-side changes that drop the nix binary but keep the
              # declarative config.toml + custom systemd user unit.
              #
              # Upstream ships a DEB822 .sources file with:
              #   URIs: https://pkg.noctalia.dev/deb/
              #   Suites: trixie/ trixie-backports/
              #   Signed-By: /usr/share/keyrings/nickh-archive-keyring.gpg
              # ansnix's apt-repo role emits a classic
              # `deb [signed-by=<path>] URL suite` line instead of DEB822,
              # which is functionally equivalent. We only take `trixie/`
              # because that's where the noctalia .deb actually lives (see
              # https://pkg.noctalia.dev/deb/trixie/); trixie-backports/ is
              # empty for noctalia today, so adding it just costs an extra
              # apt-update fetch.
              {
                name = "noctalia";
                url = "https://pkg.noctalia.dev/deb";
                keyUrl = "https://pkg.noctalia.dev/deb/nickh-archive-keyring.gpg";
                suite = "trixie/";
              }
              # NetBird — official Debian repo. Installs the `netbird`
              # daemon + `netbird-ui` tray via the apt-packages role below.
              # Config file at /etc/netbird/config.json is seeded by
              # modules/system-manager.ML-PF603JJ8/netbird.nix so the
              # daemon comes up already pointing at the corp management
              # URL. Verified against pkgs.netbird.io/install.sh (line 119).
              {
                name = "netbird";
                url = "https://pkgs.netbird.io/debian";
                keyUrl = "https://pkgs.netbird.io/debian/public.key";
                suite = "stable";
                components = [ "main" ];
              }
            ];
          };

          apt-packages = {
            priority = 100;
            after = [ "apt-repo" ];
            packages = [
              "network-manager"
              "niri"
              "xwayland-satellite"
              "libpam-gnome-keyring"
              # greetd + tuigreet: minimal TUI display manager on tty1.
              # Replaces the shell-autostart path with a proper login
              # daemon so the tty1 login → niri-session flow doesn't
              # rely on .zprofile at all. Matches the spongebob NixOS
              # host's approach (see modules/nixos.spongebob/desktop.nix).
              # NOTE: Debian ships tuigreet as a standalone package (not
              # `greetd-tuigreet` as on some other distros).
              "greetd"
              "tuigreet"
              # noctalia comes from pkg.noctalia.dev (registered above);
              # HM keeps generating ~/.config/noctalia/config.toml but no
              # longer installs the nix binary — the systemd user unit
              # execs /usr/bin/noctalia.
              "noctalia"
              # NetBird client + tray (Debian repo registered above).
              # `netbird` = daemon + CLI, `netbird-ui` = systray. Daemon
              # is systemd-system (auto-managed by the .deb), tray is
              # started under HM — see
              # modules/home-manager/desktop/netbird-tray.nix.
              "netbird"
              "netbird-ui"
            ];
          };

          pam-line = {
            priority = 110;
            requires = [ "apt-packages" ];
            lines = [
              {
                file = "/etc/pam.d/common-auth";
                line = "auth      optional     pam_gnome_keyring.so";
              }
              {
                file = "/etc/pam.d/common-session";
                line = "session   optional     pam_gnome_keyring.so auto_start";
              }
              # sudo's PAM stack `@include common-session-noninteractive`, not
              # `common-session`. Without this line the auth-side keyring hook
              # captures the password but session-side auto_start never fires,
              # so sudo can't unlock the login keyring. Mirror the hook here so
              # `sudo` (and any other noninteractive-session service) triggers
              # the unlock.
              {
                file = "/etc/pam.d/common-session-noninteractive";
                line = "session   optional     pam_gnome_keyring.so auto_start";
              }
            ];
          };
        };

        onFailure = "fail-activation";
      };

      system-manager.allowAnyDistro = true;
      nixpkgs.hostPlatform = "x86_64-linux";

      # Laptop CPU inventory. Consumed by traits (nix-throttle uses 50%).
      systemConstants.cpu.count = 16;

      # Throttle nix-daemon: keep total CPU budget at ~50% (8 of 16 cores)
      # split across parallel derivations. See modules/system-manager/nix-throttle.nix
      systemConstants.nix.throttle = {
        enable = true;
        maxJobs = 2; # 2 derivations in flight
        # cores defaults to cpu.count / (2*maxJobs) = 16 / 4 = 4 threads per build
      };

      nix.settings = {
        # /etc/nix/netrc is intentionally NOT in extra-sandbox-paths: aws-nix-cache
        # authenticates via AWS_SHARED_CREDENTIALS_FILE (see 50-aws-nix-cache.conf
        # nix-daemon drop-in), so no builder needs netrc inside the sandbox.
        # Re-add and provide the file declaratively (sops-nix / environment.etc)
        # if a fetcher in a builder ever needs it.
        trusted-users = [
          "root"
          "juliendauliac"
        ];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        system-features = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
          "uid-range"
        ];
      };
      nix.extraOptions = ''
        !include /etc/nix/conf.d/substituters.conf
      '';

      services.aws-nix-cache = {
        enable = true;
        uid = 1001;
        profile = "nix-cache";
        region = "eu-west-3";
      };

      environment.systemPackages = with pkgs; [
        earlyoom
        ananicy-cpp
        ananicy-rules-cachyos
      ];

      # Docker daemon — see modules/system-manager/docker.nix for the module.
      # `iptables` / `ip-forward` are dockerd defaults but pinned here for
      # clarity; `dns` avoids relying on systemd-resolved's stub (unreachable
      # from container netns). `bridgeFix` restores k3d bridge NAT.
      virtualisation.docker = {
        enable = true;
        users = [ "juliendauliac" ];
        daemon.settings = {
          iptables = true;
          ip-forward = true;
          dns = [
            "8.8.8.8"
            "8.8.4.4"
          ];
        };
        bridgeFix = true;
      };

      # earlyoom: kill memory-hungry processes before the kernel OOM killer freezes the system
      systemd.services.earlyoom = {
        enable = true;
        description = "Early OOM Daemon";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.earlyoom}/bin/earlyoom -m 5 -s 5 --prefer '(chromium|chrome|zen|slack|vesktop|discord|node|java|claude)' --avoid '(sshd|systemd|dockerd)' -n";
          Restart = "always";
          RestartSec = 5;
        };
      };

      # ananicy-cpp: auto-assign nice/ionice priorities per application
      systemd.services.ananicy-cpp = {
        enable = true;
        description = "Ananicy-Cpp - Community-driven process priority daemon";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.ananicy-cpp}/bin/ananicy-cpp -C ${pkgs.ananicy-rules-cachyos}/etc/ananicy.d";
          Restart = "always";
          RestartSec = 5;
          Nice = -20;
          OOMScoreAdjust = -1000;
        };
      };

      # Custom ananicy rules: de-prioritize browsers and chat apps
      environment.etc."ananicy.d/browsers.rules".text = ''
        {"name": "zen", "type": "BG_CPUIO", "nice": 15, "ioclass": "idle"}
        {"name": "zen-bin", "type": "BG_CPUIO", "nice": 15, "ioclass": "idle"}
        {"name": "chromium", "type": "BG_CPUIO", "nice": 15, "ioclass": "idle"}
        {"name": "chrome", "type": "BG_CPUIO", "nice": 15, "ioclass": "idle"}
      '';
      environment.etc."ananicy.d/chat.rules".text = ''
        {"name": "slack", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle"}
        {"name": "discord", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle"}
        {"name": "vesktop", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle"}
        {"name": "Discord", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle"}
        {"name": "Vesktop", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle"}
      '';
      environment.etc."ananicy.d/cargo.rules".text = ''
        {"name": "cargo", "type": "BG_CPUIO", "nice": 15, "ioclass": "idle", "ionice": 7}
        {"name": "cargo-clippy", "type": "BG_CPUIO", "nice": 15, "ioclass": "idle", "ionice": 7}
        {"name": "rustc", "type": "BG_CPUIO", "nice": 15, "ioclass": "idle", "ionice": 7}
        {"name": "rust-analyzer", "type": "BG_CPUIO", "nice": 15, "ioclass": "idle", "ionice": 7}
      '';
      environment.etc."ananicy.d/sentinelone.rules".text = ''
        {"name": "sentinelone-agent", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle", "ionice": 7}
        {"name": "sentinelone-watcher", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle", "ionice": 7}
        {"name": "sentinelone-scan", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle", "ionice": 7}
        {"name": "sentinelctl", "type": "BG_CPUIO", "nice": 19, "ioclass": "idle", "ionice": 7}
      '';

      # SentinelOne: cap CPU, I/O, and memory at the systemd service level
      environment.etc."systemd/system/sentinelone.service.d/50-resource-limits.conf" = {
        text = ''
          [Service]
          # CPU: lowest priority, hard-capped to 1 of 16 cores
          Nice=19
          CPUSchedulingPolicy=idle
          CPUQuota=100%
          CPUWeight=1
          AllowedCPUs=15

          # I/O: idle class, minimum weight
          IOSchedulingClass=idle
          IOSchedulingPriority=7
          IOWeight=1
          IOReadBandwidthMax=/dev/nvme0n1 50M
          IOWriteBandwidthMax=/dev/nvme0n1 50M
          IOReadIOPSMax=/dev/nvme0n1 500
          IOWriteIOPSMax=/dev/nvme0n1 500

          # Memory: soft 512M, hard 1.5G, swap discouraged
          MemoryHigh=512M
          MemoryMax=1536M
          MemorySwapMax=256M

          # Limit spawned tasks/threads
          TasksMax=128

          # Prevent network priority abuse
          IPAccounting=true
        '';
      };

      # Limit user sessions: CPU priority + hard caps on CPU/memory
      environment.etc."systemd/system/user-.slice.d/50-resource-limits.conf" = {
        text = ''
          [Slice]
          CPUWeight=80
          CPUQuota=1400%
          MemoryHigh=90%
          MemoryMax=95%
        '';
      };

      # Allow juliendauliac to manage systemd units without an interactive
      # polkit auth agent. systemctl-tui (and any other TTY TUI) can't drive
      # polkit-gnome, so `manage-units` normally fails with
      # `InteractiveAuthorizationRequired`. Debian's polkit reads
      # /etc/polkit-1/rules.d/*.rules directly.
      environment.etc."polkit-1/rules.d/50-systemctl-nopasswd.rules".text = ''
        polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.systemd1.manage-units" ||
               action.id == "org.freedesktop.systemd1.manage-unit-files" ||
               action.id == "org.freedesktop.systemd1.reload-daemon") &&
              subject.user == "juliendauliac") {
            return polkit.Result.YES;
          }
        });
      '';

      # AdminIdentities override. This host has both `juliendauliac` and
      # `manoadmin` in the `sudo` group; the polkit default of
      # `unix-group:sudo` therefore makes polkit-gnome show an
      # "authenticate as: ..." picker on every admin action. Restrict admin
      # identity to juliendauliac so the agent prompts directly for the
      # current user's password with no picker step.
      environment.etc."polkit-1/rules.d/45-admin-identities.rules".text = ''
        polkit.addAdminRule(function(action, subject) {
          return ["unix-user:juliendauliac"];
        });
      '';

      # greetd — minimal login daemon on tty1. tuigreet paints a text UI,
      # authenticates via PAM, then execs /usr/bin/niri-session as the user.
      # No shell in the launch path → no .zprofile sourcing → no exec-loop
      # foot-guns. --remember pre-fills the last successful username.
      #
      # Debian's greetd.service ships with Alias=display-manager.service and
      # WantedBy=graphical.target, so switching systemd-default-target above
      # to "graphical" is what actually starts it at boot.
      environment.etc."greetd/config.toml".text = ''
        [terminal]
        vt = 1

        [default_session]
        command = "tuigreet --time --remember --cmd '/usr/bin/niri-session'"
        user = "_greetd"
      '';

    };
}
