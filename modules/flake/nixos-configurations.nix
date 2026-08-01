{
  config,
  inputs,
  lib,
  ...
}:
let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};

  vmSshPort = 2222;
  vmSshKeyDir = ../dev;
  vmSshPubKey = builtins.readFile (vmSshKeyDir + "/vm-ssh-key.pub");

  vmModule = { lib, ... }: {
    virtualisation.vmVariant = {
      virtualisation = {
        qemu.options = [
          "-device virtio-vga-gl"
          "-display gtk,gl=on,grab-on-hover=on"
        ];
        forwardPorts = [
          {
            from = "host";
            host.port = vmSshPort;
            guest.port = 22;
          }
        ];
        memorySize = 4096;
        cores = 4;
        graphics = true;
      };

      services.openssh = {
        enable = lib.mkForce true;
        settings = {
          PermitRootLogin = lib.mkForce "yes";
          PasswordAuthentication = lib.mkForce false;
          AllowUsers = lib.mkForce [
            "gary"
            "root"
          ];
        };
      };

      users.users.root.openssh.authorizedKeys.keys = lib.mkForce [ vmSshPubKey ];
    };
  };

  mkHost =
    hostname:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        inputs.nlib.nixosModules.default
        config.flake.modules.nixos."host-${hostname}"
        vmModule
        {
          nixpkgs.hostPlatform = system;
          nixpkgs.config = config.dotfiles.nixpkgsConfig;
          nixpkgs.overlays = config.dotfiles.overlays;
        }
      ];
    };

  nixosConfigs = {
    gary = mkHost "gary";
    spongebob = mkHost "spongebob";
  };

  mkVmApp = name: nixosConfig: {
    type = "app";
    program = toString (
      pkgs.writeShellScript "run-${name}-vm" ''
        DISK="${name}.qcow2"

        if [[ -f "$DISK" ]]; then
          echo "Removing old VM disk: $DISK"
          rm -f "$DISK"
        fi

        exec ${nixosConfig.config.system.build.vm}/bin/run-${name}-vm "$@"
      ''
    );
  };

  vmSshPrivKeyStore = pkgs.runCommand "vm-ssh-key" { } ''
    cp ${vmSshKeyDir + "/vm-ssh-key"} $out
    chmod 600 $out
  '';

  mkSshApp = name: _: {
    type = "app";
    program = toString (
      pkgs.writeShellScript "ssh-${name}" ''
        USER="''${1:-${name}}"
        shift 2>/dev/null || true

        TMPKEY=$(mktemp)
        cp ${vmSshPrivKeyStore} "$TMPKEY"
        chmod 600 "$TMPKEY"
        trap "rm -f $TMPKEY" EXIT

        echo "Connecting to ${name} VM on localhost:${toString vmSshPort} as $USER..."
        exec ${pkgs.openssh}/bin/ssh -v \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -i "$TMPKEY" \
          -p ${toString vmSshPort} \
          "$USER@localhost" "$@"
      ''
    );
  };

  vmApps = lib.mapAttrs mkVmApp nixosConfigs;
  sshApps = lib.mapAttrs (name: cfg: mkSshApp name cfg) nixosConfigs;
in
{
  flake.nixosConfigurations = nixosConfigs;

  flake.apps.${system} = vmApps // {
    vm = vmApps.gary;
    ssh-gary = sshApps.gary;
    ssh-spongebob = sshApps.spongebob;
    ssh = sshApps.gary;
  };
}
