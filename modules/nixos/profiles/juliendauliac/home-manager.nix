_: {
  home-manager = {
    users.juliendauliac = {
      imports = [
        ../../../home-manager/profiles/juliendauliac.nix
        ../../../home-manager/home.nix
      ];
    };
  };
}
