{
  lib,
  inputs,
  ...
}:
{
  options.dotfiles.home = {
    sharedModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
      description = "Home-manager modules shared across all users";
    };

    userModules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.deferredModule);
      default = { };
      description = "Home-manager modules specific to each user";
    };

    externalModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = with inputs; [
        nix-index-db.homeModules.nix-index
        sops-nix.homeManagerModules.sops
        catppuccin.homeModules.catppuccin
        nixvim.homeModules.nixvim
        nix-flatpak.homeManagerModules.nix-flatpak
        betterfox-nix.modules.homeManager.betterfox
        noctalia.homeModules.default
        mcps.homeManagerModules.claude
      ];
      description = "External home-manager modules from flake inputs";
    };
  };
}
