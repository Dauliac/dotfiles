{
  flake.modules.nixos.comin = {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/dauliac/dotfiles.git";
          branches.main.name = "master";
        }
      ];
    };
  };
}
