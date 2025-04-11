_: {
  home-manager = {
    users.juliendauliac = {
      imports = [
        ../../../home-manager/profiles/juliendauliac
        ../../../home-manager/home.nix
      ];
    };
  };
}
