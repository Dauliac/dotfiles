_: {
  home-manager = {
    useGlobalPkgs = true;
    users.dauliac = {
      imports = [
        ../../../home-manager/profiles/dauliac.nix
      ];
    };
  };
}
