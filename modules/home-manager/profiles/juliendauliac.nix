{
  config,
  pkgs,
  ...
}:
{
  xdg.systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share" ];
  home.activation.setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    /run/current-system/sw/bin/systemctl start --user sops-nix
  '';
  home.packages = with pkgs; [
    kubecm
    kubectl
    glab
    fluxcd
    k9s
    mise
    pipx
    pdm
    terragrunt # need pinned version
    terraform
    vault
    # TODO: docker
    # TODO: hashcorp vault
    vsh # Hashcorp vault gui
    cloudflared
    python312 # Python
    awscli
  ];
}
