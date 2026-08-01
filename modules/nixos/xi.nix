{ inputs, ... }: {
  flake.modules.nixos.xi = {
    disabledModules = [ "programs/nh.nix" ]; # use xi flake's module instead of upstream nh
    imports = [ inputs.xi.nixosModules.default ];

    programs.xi = {
      enable = true;
      wrapNix = true;
      shellHook = {
        enable = true;
        nixAlias = true;
        completion = true;
        develop = false;
      };
    };
  };
}
