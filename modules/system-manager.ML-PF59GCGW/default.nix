{
  flake.modules.systemManager.host-ml-pf59gcgw =
    {
      lib,
      pkgs,
      ...
    }:
    {
      system-manager.allowAnyDistro = true;
      nixpkgs.hostPlatform = "x86_64-linux";

      environment.etc."nix/nix.conf" = {
        replaceExisting = true;
        text = ''
          extra-sandbox-paths = /etc/nix/netrc
          trusted-users = root juliendauliac
        '';
      };

      environment.systemPackages = with pkgs; [
        docker
        apparmor-parser
        apparmor-utils
      ];

      environment.etc."docker/daemon.json".text = builtins.toJSON {
        iptables = true;
        ip-forward = true;
        dns = [ "8.8.8.8" "8.8.4.4" ];
      };

      # Fix UFW blocking Docker bridge traffic (inter-container + outbound NAT)
      # Without this, k3d pods can't communicate or reach the internet
      systemd.services.docker-bridge-fix = {
        enable = true;
        description = "Fix UFW/Docker bridge forwarding for k3d and Docker containers";
        wantedBy = [ "multi-user.target" ];
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "docker-bridge-fix" ''
            set -eu
            export PATH="${lib.makeBinPath [ pkgs.iproute2 pkgs.iptables pkgs.gawk pkgs.procps ]}:$PATH"

            # Disable bridge-nf-call-iptables so bridge traffic skips iptables/UFW
            sysctl -w net.bridge.bridge-nf-call-iptables=0

            for br in $(ip -o link show type bridge | awk -F': ' '{print $2}' | grep '^br-'); do
              # Allow forwarding in DOCKER-USER chain (Docker's intended place for custom rules)
              iptables -C DOCKER-USER -i "$br" -j ACCEPT 2>/dev/null || iptables -I DOCKER-USER -i "$br" -j ACCEPT
              iptables -C DOCKER-USER -o "$br" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || iptables -I DOCKER-USER -o "$br" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

              # Allow forwarding in DOCKER-FORWARD chain (needed when FORWARD policy is DROP
              # and Docker only adds ACCEPT for docker0, not custom bridges like k3d)
              iptables -C DOCKER-FORWARD -i "$br" -j ACCEPT 2>/dev/null || iptables -I DOCKER-FORWARD -i "$br" -j ACCEPT
              iptables -C DOCKER-FORWARD -o "$br" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || iptables -I DOCKER-FORWARD -o "$br" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
            done

            # Ensure DOCKER-USER chain returns to caller (empty chain = implicit DROP)
            iptables -C DOCKER-USER -j RETURN 2>/dev/null || iptables -A DOCKER-USER -j RETURN

            # NAT/masquerade for Docker network ranges going to the internet
            iptables -t nat -C POSTROUTING -s 172.16.0.0/12 ! -o docker0 -j MASQUERADE 2>/dev/null || iptables -t nat -I POSTROUTING -s 172.16.0.0/12 ! -o docker0 -j MASQUERADE
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
                pkgs.docker
                pkgs.apparmor-parser
                pkgs.apparmor-utils
                pkgs.coreutils
                pkgs.kmod
              ]
            }:/usr/bin:/sbin"
          ];
          ExecStart = "${pkgs.docker}/bin/dockerd";
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
