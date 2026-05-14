{ inputs, ... }:
let
  xdgConfigDir = ./xdg-config;
in
{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      imports = [
        inputs.nix-index-db.homeModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
        inputs.catppuccin.homeModules.catppuccin
        inputs.stylix.homeModules.stylix
        inputs.nixvim.homeModules.nixvim
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.betterfox-nix.modules.homeManager.betterfox
        inputs.noctalia.homeModules.default
        inputs.mcps.homeManagerModules.claude
      ];

      home.stateVersion = "25.05";
      home.enableNixpkgsReleaseCheck = false;
      home.file."${config.xdg.configHome}" = {
        source = xdgConfigDir;
        recursive = true;
      };
      fonts.fontconfig.enable = true;
      xdg.enable = true;
      xdg.mime.enable = true;
      xdg.mimeApps.enable = true;
      xdg.configFile."mimeapps.list".force = true;
      xdg.systemDirs.data = [
        "${config.home.profileDirectory}/share"
        "/nix/var/nix/profiles/default/share"
      ];
      home.sessionVariables = {
        BROWSER = "zen";
      };
    };
}
