{ config
, pkgs
, ...
}:
let
  nixGL = pkgs.nixgl.nixGLIntel;
  nixGlWrapper = pkg:
    pkgs.buildEnv {
      name = "nixGL-${pkg.name}";
      paths =
        [ pkg ]
        ++ (map
          (bin:
            pkgs.hiPrio (pkgs.writeShellScriptBin bin ''
              exec -a "$0" "${nixGL}/bin/nixGLIntel" "${pkg}/bin/${bin}" "$@"
            ''))
          (builtins.attrNames (builtins.readDir "${pkg}/bin")));
    };
in
{
  # WARN: set it to true segfault nautilus in non nixOs systems
  xdg.mime.enable = false;
  xdg.systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share" ];
  home.activation.setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/systemctl start --user sops-nix
  '';
  home.packages = with pkgs; [
    kgs.firefox-devedition
    jira-cli-go
    slack
  ];
  programs = {
    wezterm.package = nixGlWrapper pkgs.wezterm;
    # alacritty.package = nixGlWrapper pkgs.alacritty;
  };
}
