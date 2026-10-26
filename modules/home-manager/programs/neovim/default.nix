{
  flake.modules.homeManager.neovim = {
    home.sessionVariables = {
      VISUAL = "nvim";
    };
    programs.nixvim = {
      enable = true;
      # nixvim pins its own nixpkgs source via `inputs.follows`, so it does
      # NOT inherit `dotfiles.nixpkgsConfig.allowUnfree`. cmp-spell was
      # relicensed to unfree in nixpkgs 26.05, so we have to re-grant unfree
      # explicitly for the nixvim pkgs instance.
      nixpkgs.config.allowUnfree = true;
    };
  };
}
