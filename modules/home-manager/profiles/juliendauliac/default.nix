{ config
, pkgs
, ...
}:
let
  nixGL = pkgs.nixgl.nixGLIntel;
  nixGlWrapper =
    pkg:
    pkgs.buildEnv {
      name = "nixGL-${pkg.name}";
      paths =
        [ pkg ]
        ++ (map
          (
            bin:
            pkgs.hiPrio (
              pkgs.writeShellScriptBin bin ''
                exec -a "$0" "${nixGL}/bin/nixGLIntel" "${pkg}/bin/${bin}" "$@"
              ''
            )
          )
          (builtins.attrNames (builtins.readDir "${pkg}/bin")));
    };
in
{
  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
    NPM_CONFIG_PREFIX = "$XDG_DATA_HOME/npm-packages";
    PATH = "$PATH:$NPM_CONFIG_PREFIX/bin/";
  };
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };
  home.packages = with pkgs; [
    awscli2
    cloudflared
    cloudlens
    fluxcd
    jetbrains.pycharm-professional
    glab
    google-chrome
    docker-compose
    kubecm
    kubectl
    kubelogin
    kubelogin-oidc
    okta-aws-cli
    granted
    pdm
    pipx
    python312
    python313Packages.virtualenv
    terraform
    terragrunt
    vault
    vsh
    nodejs_20
    skopeo
    lazydocker
    pnpm_10
    oha
    slack
    pre-commit
    vesktop
    ruby
    just
    dbeaver-bin
    vector
  ];
  home.sessionVariables = {
    AWS_DEFAULT_PROFILE = "manomano-support";
  };
  programs.git.includes = [
    {
      inherit (config.sops.secrets.git) path;
    }
  ];
  programs.wezterm.package = nixGlWrapper pkgs.wezterm;
  services.flatpak = {
    enable = true;
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
