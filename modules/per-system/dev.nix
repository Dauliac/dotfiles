{ lib, ... }: {
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
      xi.shellHook = {
        enable = true;
        nixAlias = true;
        completion = true;
        develop = true;
      };

      devShells.default = config.xi.wrapDevShell (
        pkgs.mkShell {
          nativeBuildInputs =
            with pkgs;
            [
              # zsh is here because xi develop enter execvp's `zsh` after
              # sourcing the devshell env; the outer ~/.nix-profile/bin/zsh
              # isn't reachable once PATH is replaced by the devshell.
              zsh
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

          shellHook = ''
            ${config.pre-commit.installationScript}
            export SOPS_AGE_KEY_FILE=~/.config/sops/age/dotfiles.txt
            git config diff.sopsdiffer.textconv "sops decrypt"
            task init
          '';
        }
      );
    };
}
