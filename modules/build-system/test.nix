{ lib, ... }:
{
  config.perSystem =
    { pkgs, ... }:
    {
      packages = {
        dev = pkgs.nixosTest {
          name = "test-infra-nixos";
          nodes.nixos =
            { config, ... }:
            let
              user = "dauliac";
            in
            {
              imports = config.nixOsModules;
              services.openssh.settings.PermitRootLogin = "yes";
              services.xserver.displayManager.autoLogin.enable = true;
              services.xserver.displayManager.autoLogin.user = user;
              services.xserver.displayManager.gdm.enable = lib.mkForce false;
              virtualisation = {
                graphics = true;
                qemu.options = [ "-vga none -device virtio-gpu-pci" ];
                # NOTE: these are finetuned for my personal computer only
                memorySize = 3000;
                cores = 5;
                sharedDirectories = {
                  sources = {
                    source = builtins.toString ../../.;
                    target = "/mnt/sources";
                  };
                };
              };
            };
          testScript = ''
            nixos.succeed("wezterm start zsh -c 'exit 0'")
            nixos.succeed("ls")
          '';
        };
      };
    };
}
