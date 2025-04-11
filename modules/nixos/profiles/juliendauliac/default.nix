{inputs, ...}:
{
    # TODO: add disko for lusk setup
    imports = [
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen4
        ./users.nix
        ./home-manager.nix
        ./hardware.nix
        ./flatpak.nix
        ./desktop.nix
        ./secrets.nix
    ];
    config = {
        networking.hostName = "manomano";
    };
}
