{
  config,
  pkgs,
  ...
}:
{
  # WARN: set it to true segfault nautilus in non nixOs systems
  xdg.mime.enable = false;
  xdg.systemDirs.data = [ "${config.home.homeDirectory}/.nix-profile/share" ];
  home.activation.setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    /usr/bin/systemctl start --user sops-nix
  '';
  home.packages = with pkgs; [
    # gptcommit
    
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
