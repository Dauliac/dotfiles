{inputs, ...}: 
{
    imports = [
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen4
        ./users.nix
        ./home-manager.nix
        ./boot.nix
        ./flatpak.nix
    ];
}