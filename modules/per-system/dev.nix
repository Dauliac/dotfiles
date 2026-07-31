{ lib, ... }:
{
  config.perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    {
      xi.enable = true;
      xi.devshell.enable = true;

      devShells.default = config.xi.wrapDevShell (
        pkgs.mkShell {
          shellHook = config.pre-commit.installationScript;
          nativeBuildInputs =
            with pkgs;
            [
              lefthook
              sops
              age
              go-task
              ssh-to-age
              nix-output-monitor
              inputs'.home-manager.packages.home-manager
              inputs'.system-manager.packages.default
              config.treefmt.build.wrapper
            ]
            ++ (lib.attrValues config.treefmt.build.programs);

          devShellHook = ''
            export SOPS_AGE_KEY_FILE=~/.config/sops/age/dotfiles.txt
            git config diff.sopsdiffer.textconv "sops decrypt"
            task init
            task
          '';
        }
      );
    };
}
