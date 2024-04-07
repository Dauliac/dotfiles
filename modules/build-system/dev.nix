{
  inputs,
  lib,
  ...
}: {
  config.perSystem = {
    config,
    inputs',
    pkgs,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      nativeBuildInputs = with pkgs;
        [
          lefthook
          sops
          age
          ssh-to-age
          inputs'.home-manager.packages.home-manager
          inputs'.disko.packages.disko
        ]
        ++ config.linters
        ++ config.formatterPackages;
      devShellHook = ''
        git config diff.sopsdiffer.textconv "sops decrypt"
      '';
    };
  };
}
