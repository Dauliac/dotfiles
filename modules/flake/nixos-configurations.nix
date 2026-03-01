{
  config,
  inputs,
  lib,
  ...
}:
let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};

  # SSH port for VM (host port -> guest port 22)
  vmSshPort = 2222;

  # Dev SSH key for VM access (stored in repo)
  vmSshKeyDir = ../dev;
  vmSshPubKey = builtins.readFile (vmSshKeyDir + "/vm-ssh-key.pub");

  # VM configuration module for dev environment
  vmModule =
    { lib, ... }:
    {
      virtualisation.vmVariant = {
        virtualisation = {
          # Use virtio-gpu with GTK display
          # Press Ctrl+Alt+G to toggle keyboard/mouse grab
          qemu.options = [
            "-device virtio-vga-gl"
            "-display gtk,gl=on,grab-on-hover=on"
          ];
          # SSH port forwarding: host 2222 -> guest 22
          forwardPorts = [
            {
              from = "host";
              host.port = vmSshPort;
              guest.port = 22;
            }
          ];
          # Reasonable defaults for testing
          memorySize = 4096;
          cores = 4;
          # Enable graphics
          graphics = true;
        };

        # Enable SSH in the VM with dev key
        services.openssh = {
          enable = lib.mkForce true;
          settings = {
            PermitRootLogin = lib.mkForce "yes";
            PasswordAuthentication = lib.mkForce false;
            # Override AllowUsers to include gary and root for VM access
            AllowUsers = lib.mkForce [
              "gary"
              "root"
            ];
          };
        };

        # Add dev SSH key for root and gary
        users.users.root.openssh.authorizedKeys.keys = lib.mkForce [ vmSshPubKey ];
        users.users.gary.openssh.authorizedKeys.keys = lib.mkForce [ vmSshPubKey ];
      };
    };

  mkHost =
    hostname:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
      };
      modules =
        config.dotfiles.nixos.externalModules
        ++ config.dotfiles.nixos.sharedModules
        ++ (config.dotfiles.nixos.hostModules.${hostname} or [ ])
        ++ [
          vmModule
          { nixpkgs.hostPlatform = system; }
          { networking.hostName = hostname; }
          {
            nixpkgs.config = config.dotfiles.nixpkgsConfig;
            nixpkgs.overlays = config.dotfiles.overlays;
          }
          {
            home-manager = {
              useGlobalPkgs = true;
              sharedModules = config.dotfiles.home.externalModules ++ config.dotfiles.home.sharedModules;
              extraSpecialArgs = {
                inherit inputs;
                nixGlWrapper = config.lib.nixgl.wrapPackage;
                # Disable proprietary software in dev VMs for faster builds
                proprietaryEnabled = false;
              };
              # Users must be defined here - hostModules deferred evaluation doesn't work for home-manager.users
              # userModules.gary contains Firefox, packages, etc specific to gary user
              users.gary = {
                imports = config.dotfiles.home.userModules.gary or [ ];
                home.stateVersion = "25.05";
              };
            };
          }
        ];
    };

  # Create VM configurations
  nixosConfigs = {
    gary = mkHost "gary";
    spongebob = mkHost "spongebob";
  };

  # Create a VM app for each nixosConfiguration (always starts fresh)
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

  # Copy private key with correct permissions for SSH
  vmSshPrivKeyStore = pkgs.runCommand "vm-ssh-key" { } ''
    cp ${vmSshKeyDir + "/vm-ssh-key"} $out
    chmod 600 $out
  '';

  # Create SSH connection app for each host
  mkSshApp = name: _: {
    type = "app";
    program = toString (
      pkgs.writeShellScript "ssh-${name}" ''
        USER="''${1:-${name}}"
        shift 2>/dev/null || true

        # Copy key to temp with correct permissions (nix store is read-only)
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

  # VM runner and SSH apps
  flake.apps.${system} = vmApps // {
    vm = vmApps.gary; # Default to gary

    # SSH connection apps
    ssh-gary = sshApps.gary;
    ssh-spongebob = sshApps.spongebob;
    ssh = sshApps.gary; # Default SSH target
  };
}
