_: {
  home-manager = {
    useGlobalPkgs = true;
    users.juliendauliac = {
      imports = [
        ../../../home-manager/profiles/juliendauliac.nix
      ];
    };
  };
}
