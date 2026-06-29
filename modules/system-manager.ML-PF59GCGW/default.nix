{ inputs, ... }:
{
  flake.modules.systemManager.host-ml-pf59gcgw =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.aws-nix-cache.systemManagerModules.default
      ];

      system-manager.allowAnyDistro = true;
      nixpkgs.hostPlatform = "x86_64-linux";

      environment.etc."nix/nix.conf" = {
        replaceExisting = true;
        text = ''
          extra-sandbox-paths = /etc/nix/netrc
          trusted-users = root juliendauliac
          !include /etc/nix/conf.d/substituters.conf
        '';
      };

      services.aws-nix-cache = {
        enable = true;
        uid = 1001;
        profile = "nix-cache";
        region = "eu-west-3";
      };

      environment.systemPackages = with pkgs; [
        docker_29
        apparmor-parser
        apparmor-utils
        earlyoom
        ananicy-cpp
        ananicy-rules-cachyos
      ];

      environment.etc."docker/daemon.json".text = builtins.toJSON {
        iptables = true;
        ip-forward = true;
        dns = [
          "8.8.8.8"
          "8.8.4.4"
        ];
      };

      # Fix UFW blocking Docker bridge traffic (inter-container + outbound NAT)
      # Without this, k3d pods can't communicate or reach the internet
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
          # CPU: lowest priority, hard-capped to 2 of 16 cores
          Nice=19
          CPUSchedulingPolicy=idle
          CPUQuota=200%
          CPUWeight=1
          AllowedCPUs=14-15

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

      systemd.services.docker-bridge-fix = {
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

            # Disable bridge-nf-call-iptables so bridge traffic skips UFW filtering
            sysctl -w net.bridge.bridge-nf-call-iptables=0 || true

            # Docker uses nftables but only creates filter/forward rules for docker0.
            # Custom bridge networks (k3d, etc.) are missing DOCKER-CT, DOCKER-BRIDGE,
            # and DOCKER-FORWARD accept rules, so traffic is dropped by the FORWARD
            # chain's default DROP policy.
            for br in $(ip -o link show type bridge | awk -F': ' '{print $2}' | grep '^br-'); do
              echo "Fixing nftables rules for bridge: $br"

              # Allow return traffic (established/related connections) to the bridge
              nft add rule ip filter DOCKER-CT oifname "$br" ct state related,established counter accept

              # Jump to DOCKER chain for traffic destined to the bridge (port forwarding)
              nft add rule ip filter DOCKER-BRIDGE oifname "$br" counter jump DOCKER

              # Allow all forwarded traffic originating from the bridge (outbound internet)
              nft add rule ip filter DOCKER-FORWARD iifname "$br" counter accept
            done
          '';
        };
      };

      systemd.services.docker = {
        enable = true;
        description = "Docker Application Container Engine";
        documentation = [ "https://docs.docker.com" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        requires = [ "apparmor.service" ];
        serviceConfig = {
          Type = "notify";
          Environment = [
            "PATH=${
              lib.makeBinPath [
                pkgs.docker_29
                pkgs.nftables
                pkgs.apparmor-parser
                pkgs.apparmor-utils
                pkgs.coreutils
                pkgs.kmod
              ]
            }:/usr/bin:/sbin"
          ];
          ExecStart = "${pkgs.docker_29}/bin/dockerd";
          ExecStartPost = [
            "${pkgs.coreutils}/bin/chmod 666 /var/run/docker.sock"
            "${pkgs.coreutils}/bin/chown root:docker /var/run/docker.sock"
          ];
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
    };
}
