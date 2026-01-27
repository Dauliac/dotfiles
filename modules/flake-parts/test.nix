{
  lib,
  config,
  inputs,
  ...
}:
{
  config.perSystem =
    { pkgs, ... }:
    {
      packages = {
        dev = pkgs.testers.runNixOSTest {
          name = "nixos";
          nodes.nixos = {
            specialArgs = { inherit inputs; };
            imports = config.nixOsModules;

            services.comin = {
              enable = lib.mkForce false;
            };
            services.greetd.enable = lib.mkForce false;
            services.openssh.settings.PermitRootLogin = "yes";
            services.displayManager.autoLogin.enable = true;
            services.displayManager.autoLogin.user = "dauliac";
            services.displayManager.gdm.enable = lib.mkForce false;

            virtualisation = {
              graphics = true;
              qemu.options = [ "-vga none -device virtio-gpu-pci" ];
              # NOTE: these are finetuned for my personal computer only
              memorySize = 3000;
              cores = 5;
              # sharedDirectories = {
              #   sources = {
              #     source = builtins.toString ../../.;
              #     target = "/mnt/sources";
              #   };
              # };
            };
          };
          testScript = ''
            # nixos.succeed("wezterm start zsh -c 'exit 0'")
            nixos.succeed("ls")
          '';
        };
      };
    };
}
