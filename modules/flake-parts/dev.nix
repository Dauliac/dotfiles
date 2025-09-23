_: {
  config.perSystem =
    {
      config,
      inputs',
      pkgs,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs =
          with pkgs;
          [
            lefthook
            sops
            age
            go-task
            ssh-to-age
            # nixGL
            inputs'.home-manager.packages.home-manager
            inputs'.disko.packages.disko
            inputs'.system-manager.packages.default
            inputs'.omnix.packages.default
            config.treefmt.build.wrapper
          ]
          ++ (lib.attrValues config.treefmt.build.programs);

        devShellHook = ''
          export SOPS_AGE_KEY_FILE=~/.config/sops/age/dotfiles.txt
          git config diff.sopsdiffer.textconv "sops decrypt"
          task init
          task
        '';
      };
    };
}
