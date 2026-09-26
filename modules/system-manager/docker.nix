{ ... }:
{
  # Docker daemon module for system-manager (non-NixOS) hosts. Ports the shape
  # of NixOS's `virtualisation.docker` (nixos/modules/virtualisation/docker.nix)
  # onto system-manager's option surface — socket activation + userborn-managed
  # group membership so pre-existing distro users can be added declaratively.
  #
  # Usage:
  #   imports = [ inputs.self.modules.systemManager.docker ];
  #   virtualisation.docker = {
  #     enable = true;
  #     users  = [ "alice" ];              # existing distro users → docker group
  #     daemon.settings = { dns = [ "8.8.8.8" ]; };
  #     bridgeFix = true;                  # k3d / custom bridge NAT fix
  #   };
  flake.modules.systemManager.docker =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.virtualisation.docker;
      daemonJson = builtins.toJSON cfg.daemon.settings;
    in
    {
      options.virtualisation.docker = {
        enable = lib.mkEnableOption ''
          the docker daemon on a system-manager host. Provides socket
          activation (systemd owns /var/run/docker.sock with mode 0660 root:docker),
          a declarative `docker` group with `users` as members (reconciled by
          userborn), overlay/br_netfilter modprobe, ip_forward sysctl, and an
          optional bridge-fix shim for custom bridge networks.
        '';

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.docker_29;
          defaultText = lib.literalExpression "pkgs.docker_29";
          description = "The docker package used for both the daemon and the CLI.";
        };

        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "juliendauliac" ];
          description = ''
            Existing distro usernames to add to the `docker` group. Reconciled
            by userborn (services.userborn.enable is set automatically when
            this module is enabled); pre-existing group members that aren't
            listed here are preserved.
          '';
        };

        daemon.settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          example = {
            iptables = true;
            ip-forward = true;
            dns = [
              "8.8.8.8"
              "8.8.4.4"
            ];
          };
          description = ''
            Attrset serialized to /etc/docker/daemon.json. See
            https://docs.docker.com/reference/cli/dockerd/#daemon-configuration-file
            for the full option list. Do NOT set `hosts` here — the module
            already passes `--host=fd://` on the CLI and dockerd rejects
            configuring hosts in both places.
          '';
        };

        bridgeFix = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Enable docker-bridge-fix.service — a oneshot that adds the missing
            DOCKER-CT / DOCKER-BRIDGE / DOCKER-FORWARD nftables accept rules
            for custom bridge networks (k3d, docker-compose networks, etc.)
            that Docker's iptables integration doesn't create by default.
            Also disables bridge-nf-call-iptables so bridge traffic skips
            UFW filtering.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];

        environment.etc."docker/daemon.json".text = daemonJson;

        # Kernel networking knobs dockerd needs. On NixOS this would be
        # `boot.kernel.sysctl`; system-manager doesn't expose that option
        # (numtide/system-manager#382), so drop it as an /etc/sysctl.d file
        # and it gets applied on next systemd-sysctl activation.
        environment.etc."sysctl.d/50-docker.conf".text = ''
          net.ipv4.conf.all.forwarding = 1
          net.ipv4.conf.default.forwarding = 1
        '';

        # userborn is what actually reconciles users.groups.<name>.members
        # into /etc/group on activation. Turning it on is idempotent — existing
        # distro-created users and their groups are preserved (verified by
        # system-manager's existing-group-members container test).
        services.userborn.enable = true;

        users.groups.docker = {
          members = cfg.users;
        };

        # Runtime + data dirs. On NixOS these would be created by dockerd's
        # bundled tmpfiles snippet pulled in via `systemd.packages = [ pkgs.docker ]`;
        # on system-manager we declare them explicitly so activation ordering
        # doesn't depend on package-provided tmpfiles.d fragments.
        systemd.tmpfiles.rules = [
          "d /var/lib/docker 0710 root root -"
          "d /var/run/docker 0755 root root -"
          "d /etc/docker     0755 root root -"
        ];

        # Socket activation. systemd creates /var/run/docker.sock with mode
        # 0660 root:docker BEFORE dockerd starts and passes the fd via
        # `--host=fd://`. Replaces the chown/chmod ExecStartPost dance that
        # failed when the docker group didn't exist.
        systemd.sockets.docker = {
          enable = true;
          description = "Docker Socket for the API";
          wantedBy = [ "sockets.target" ];
          socketConfig = {
            ListenStream = "/var/run/docker.sock";
            SocketMode = "0660";
            SocketUser = "root";
            SocketGroup = "docker";
          };
        };

        systemd.services.docker = {
          enable = true;
          description = "Docker Application Container Engine";
          documentation = [ "https://docs.docker.com" ];
          wantedBy = [ "multi-user.target" ];
          after = [
            "network-online.target"
            "docker.socket"
            "apparmor.service"
          ];
          wants = [ "network-online.target" ];
          requires = [ "docker.socket" ];
          serviceConfig = {
            Type = "notify";
            Environment = [
              "PATH=${
                lib.makeBinPath [
                  cfg.package
                  pkgs.iptables
                  pkgs.nftables
                  pkgs.apparmor-parser
                  pkgs.apparmor-utils
                  pkgs.coreutils
                  pkgs.kmod
                ]
              }:/usr/bin:/usr/sbin:/sbin"
            ];
            # boot.kernelModules isn't available on system-manager
            # (numtide/system-manager#382). Load overlay + br_netfilter here
            # before dockerd starts. Leading `-` = non-fatal on already-loaded.
            ExecStartPre = [
              "-${pkgs.kmod}/bin/modprobe overlay"
              "-${pkgs.kmod}/bin/modprobe br_netfilter"
            ];
            # daemon.json at /etc/docker/daemon.json is read by default.
            ExecStart = "${cfg.package}/bin/dockerd --host=fd://";
            ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
            TimeoutStartSec = 0;
            RestartSec = 2;
            Restart = "always";
            StartLimitBurst = 3;
            StartLimitInterval = "60s";
            LimitNOFILE = "infinity";
            LimitNPROC = "infinity";
            LimitCORE = "infinity";
            TasksMax = "infinity";
            Delegate = true;
            KillMode = "process";
            OOMScoreAdjust = -500;
          };
        };

        systemd.services.docker-bridge-fix = lib.mkIf cfg.bridgeFix {
          enable = true;
          description = "Fix Docker bridge forwarding for custom networks (k3d, etc.)";
          wantedBy = [ "multi-user.target" ];
          after = [ "docker.service" ];
          requires = [ "docker.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "docker-bridge-fix" ''
              set -eu
              export PATH="${
                lib.makeBinPath [
                  pkgs.iproute2
                  pkgs.nftables
                  pkgs.gawk
                  pkgs.procps
                ]
              }:$PATH"

              # Bridge traffic skips UFW filtering.
              sysctl -w net.bridge.bridge-nf-call-iptables=0 || true

              # Docker uses nftables but only creates filter/forward rules for
              # docker0. Custom bridge networks (k3d, etc.) are missing
              # DOCKER-CT, DOCKER-BRIDGE, and DOCKER-FORWARD accept rules, so
              # traffic is dropped by the FORWARD chain's default DROP policy.
              for br in $(ip -o link show type bridge | awk -F': ' '{print $2}' | grep '^br-'); do
                echo "Fixing nftables rules for bridge: $br"
                nft add rule ip filter DOCKER-CT oifname "$br" ct state related,established counter accept
                nft add rule ip filter DOCKER-BRIDGE oifname "$br" counter jump DOCKER
                nft add rule ip filter DOCKER-FORWARD iifname "$br" counter accept
              done
            '';
          };
        };
      };
    };
}
