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
  services.flatpak = {
    packages = [
      {
        appId = "com.slack.Slack";
        origin = "flathub";
      }
      {
        appId = "app.zen_browser.zen";
        origin = "flathub";
      }
      {
        appId = "io.appflowy.AppFlowy";
        origin = "flathub";
      }
      {
        appId = "dev.vencord.Vesktop";
        origin = "flathub";
      }
    ];
  };
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
      ovpn_client_ca = {
          sopsFile = ./openvpn/ca.enc.crt;
          path = "/home/juliendauliac/.config/openvpn/client/ca.crt";
          format = "binary";
        };
        ovpn_client_cert = {
          sopsFile = ./openvpn/client.enc.crt;
          path = "/home/juliendauliac/.config/openvpn/client09202.crt";
          format = "binary";
        };
        ovpn_client_key = {
          sopsFile = ./openvpn/client.enc.key;
          path = "/home/juliendauliac/.config/openvpn/client/client09202.key";
          format = "binary";
        };
        ovpn_client_config = {
          sopsFile = ./openvpn/client.enc.ovpn;
          path = "/home/juliendauliac/.config/openvpn/client/config.ovpn";
          format = "binary";
        };
    };
  };
}
