{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../desktop
  ];
  home.activation.setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    /run/current-system/sw/bin/systemctl start --user sops-nix
  '';
  home.packages = with pkgs; [
    awscli2
    cloudflared
    cloudlens
    fluxcd
    glab
    google-chrome
    k9s
    kubecm
    kubectl
    kubelogin
    kubelogin-oidc
    mise
    okta-aws-cli
    pdm
    pipx
    python312 # Python
    terraform
    terragrunt
    vault
    vsh
    nodejs_20
    skopeo
    lazydocker
    pnpm_10
  ];
  home.sessionVariables = {
    AWS_DEFAULT_PROFILE = "manomano-support";
  };
  programs.git.includes = [
    {
      path = config.sops.secrets.git.path;
    }
  ];
  sops = {
    secrets = {
      git = {
        sopsFile = ./gitconfig.enc.ini;
        path = "/home/juliendauliac/.config/git/secrets";
        format = "ini";
      };
      aws = {
        sopsFile = ./aws-config.enc.toml;
        path = "/home/juliendauliac/.aws/config";
        format = "binary";
      };
      sshIdRsa = {
        sopsFile = ./id_rsa.enc;
        path = "/home/juliendauliac/.ssh/id_rsa";
        format = "binary";
      };
      sshIdRsaPub = {
        sopsFile = ./id_rsa.enc.pub;
        path = "/home/juliendauliac/.ssh/id_rsa.pub";
        format = "binary";
      };
      glab = {
        sopsFile = ./glab-config.enc;
        path = "/home/juliendauliac/.config/glab-cli/config.yml";
        format = "binary";
      };
    };
  };
}
