{
  lib,
  inputs,
  ...
}:
{
  options.dotfiles.nixos = {
    sharedModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
      description = "NixOS modules shared across all hosts";
    };

    hostModules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.deferredModule);
      default = { };
      description = "NixOS modules specific to each host";
    };

    externalModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = with inputs; [
        catppuccin.nixosModules.catppuccin
        comin.nixosModules.comin
        home-manager.nixosModules.home-manager
        nix-flatpak.nixosModules.nix-flatpak
        nur.modules.nixos.default
        sops-nix.nixosModules.sops
      ];
      description = "External NixOS modules from flake inputs";
    };
  };
}
