{ ... }: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.dauliac = ../home-manager/home.nix;
  };
}
