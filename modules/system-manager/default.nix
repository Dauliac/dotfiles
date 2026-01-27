{
  lib,
  pkgs,
  ...
}:
let
  # Create the niri desktop file as a derivation
  niriDesktopFile = pkgs.writeText "niri.desktop" ''
    [Desktop Entry]
    Name=Niri
    Comment=A scrollable-tiling Wayland compositor
    Exec=/home/juliendauliac/.nix-profile/bin/niri-session
    Type=Application
  '';
in
{
  config = {
    system-manager.allowAnyDistro = true;
    nixpkgs.hostPlatform = "x86_64-linux";

    # Nix daemon settings
    nix.settings = {
      # Allow netrc file in sandbox for private Maven/Artifactory authentication
      extra-sandbox-paths = [ "/etc/nix/netrc" ];
    };
    environment = {
      systemPackages = with pkgs; [
        docker
        apparmor-parser
        apparmor-utils
        hyprland
        niri
      ];
    };

    # Create Niri session file for GDM
    # C+ = copy file, replace if exists
    systemd.tmpfiles.rules = [
      "C+ /usr/share/wayland-sessions/niri.desktop 0644 root root - ${niriDesktopFile}"
    ];

    systemd.services = {
      docker = {
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
  };
}
