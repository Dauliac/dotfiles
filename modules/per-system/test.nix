{ inputs, ... }: {
  config.perSystem = { pkgs, ... }: {
    packages = {
      # Basic NixOS VM test - minimal test that the system boots
      # Full integration testing should use the actual nixosConfigurations
      dev = pkgs.testers.runNixOSTest {
        name = "nixos";
        nodes.nixos = {
          # Only import modules that don't require specialArgs or set nixpkgs.overlays
          imports = [
            inputs.catppuccin.nixosModules.catppuccin
          ];

          # Basic catppuccin config for testing
          catppuccin = {
            enable = true;
            flavor = "mocha";
          };

          services.openssh.settings.PermitRootLogin = "yes";

          virtualisation = {
            graphics = false;
            memorySize = 1024;
            cores = 2;
          };
        };
        testScript = ''
          nixos.wait_for_unit("multi-user.target")
          nixos.succeed("ls")
        '';
      };
    };
  };
}
