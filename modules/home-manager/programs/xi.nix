{ inputs, ... }:
{
  flake.modules.homeManager.xi = {
    disabledModules = [ "programs/nh.nix" ]; # use xi flake's module instead of upstream nh
    imports = [ inputs.xi.homeManagerModules.default ];

    programs.xi = {
      enable = true;
      shellHook = {
        enable = true;
        nixAlias = true;
        completion = true;
        develop = true;
      };
    };
  };
}
