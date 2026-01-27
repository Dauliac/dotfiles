{
  config,
  lib,
  pkgs,
  ...
}:
let
  nixGL = pkgs.nixgl.nixGLIntel;
  nixGlWrapper =
    pkg:
    let
      binaries = builtins.filter (name: name != ".ghostty-wrapped" && !pkgs.lib.hasPrefix "." name) (
        builtins.attrNames (builtins.readDir "${pkg}/bin")
      );
    in
    pkgs.symlinkJoin {
      name = "nixGL-${pkg.name}";
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        # Wrap each binary with nixGL
        for bin in ${builtins.concatStringsSep " " binaries}; do
          rm -f "$out/bin/$bin"
          makeWrapper "${nixGL}/bin/nixGLIntel" "$out/bin/$bin" \
            --add-flags "${pkg}/bin/$bin"
        done

        # Patch systemd service files to use wrapped binary
        if [ -d "$out/share/systemd/user" ]; then
          for f in "$out/share/systemd/user"/*.service; do
            if [ -f "$f" ]; then
              rm -f "$f"
              sed "s|${pkg}/bin/|$out/bin/|g" "${pkg}/share/systemd/user/$(basename "$f")" > "$f"
            fi
          done
        fi

        # Patch dbus service files
        if [ -d "$out/share/dbus-1/services" ]; then
          for f in "$out/share/dbus-1/services"/*.service; do
            if [ -f "$f" ]; then
              rm -f "$f"
              sed "s|${pkg}/bin/|$out/bin/|g" "${pkg}/share/dbus-1/services/$(basename "$f")" > "$f"
            fi
          done
        fi

        # Patch desktop files
        if [ -d "$out/share/applications" ]; then
          for f in "$out/share/applications"/*.desktop; do
            if [ -f "$f" ]; then
              rm -f "$f"
              sed "s|${pkg}/bin/|$out/bin/|g" "${pkg}/share/applications/$(basename "$f")" > "$f"
            fi
          done
        fi
      '';
    };
in
{
  imports = [
    ../../desktop
  ];
  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
    NPM_CONFIG_PREFIX = "$XDG_DATA_HOME/npm-packages";
    PATH = "$PATH:$NPM_CONFIG_PREFIX/bin/:$HOME/${config.programs.go.goBin}";
  };
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    # settings = {
    #   experimental = true;
    # };
  };
  home.packages = with pkgs; [
    awscli2
    cloudflared
    cloudlens
    fluxcd
    jetbrains.pycharm
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
    ruby
    just
    (nixGlWrapper prismlauncher)
    dbeaver-bin
    vector
    jetbrains.goland
    jetbrains.pycharm
    yq
    ansible
    minio-client
    # cue
    gemini-cli-bin
  ];

  home.shellAliases = {
    vault_all = ''
      for ENV in int stg prd support ist; do
        export VAULT_ADDR=https://vault-eu-west-3.$ENV.manomano.com
        export VAULT_''${ENV}_TOKEN=$(vault login -token-only -path=sso -method=oidc role=sre | grep hvs)
      done'';
  };
  home.sessionVariables = {
    AWS_DEFAULT_PROFILE = "manomano-support";
  };

  programs.git.settings = {
    # Default: personal Dauliac account (bypass agent to use correct key)
    core.sshCommand = "SSH_AUTH_SOCK= ssh -i ~/.ssh/id_ed25519.perso -o IdentitiesOnly=yes";
    include = {
      inherit (config.sops.secrets.gitDauliac) path;
    };
    # Work: juliendauliac account with id_rsa key
    "includeIf \"gitdir:**/*manomano*/**\"" = {
      inherit (config.sops.secrets.gitJulienDauliac) path;
    };
  };

  # Work git config with different SSH key
  home.file.".config/git/manomano-ssh.inc".text = ''
    [core]
      sshCommand = ssh -i ~/.ssh/id_rsa -o IdentitiesOnly=yes
  '';

  programs.git.includes = [
    {
      condition = "gitdir:**/*manomano*/**";
      path = "~/.config/git/manomano-ssh.inc";
    }
  ];

  # Include work SSH config
  programs.ssh.includes = [ "config-mm" ];

  programs.wezterm.package = nixGlWrapper pkgs.wezterm;
  programs.alacritty.package = nixGlWrapper pkgs.alacritty;
  programs.ghostty.package = nixGlWrapper pkgs.ghostty;
  programs.kitty.package = nixGlWrapper pkgs.kitty;
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
        appId = "dev.vencord.Vesktop";
        origin = "flathub";
      }
    ];
  };
  sops = {
    secrets = {
      # context7 = {
      #   sopsFile = ./aws-config.enc.toml;
      #   path = "/home/juliendauliac/.config/secrets/context7";
      #   format = "env";
      # };
      aws = {
        sopsFile = ./aws-config.enc.toml;
        path = "/home/juliendauliac/.aws/config";
        format = "binary";
      };
      gitJulienDauliacRoot = {
        sopsFile = ./gitconfig.root.enc.ini;
        path = "/home/juliendauliac/.gitconfig";
        format = "ini";
      };
      gitJulienDauliac = {
        sopsFile = ./gitconfig.enc.ini;
        path = "/home/juliendauliac/.config/git/juliendauliac.secrets.ini";
        format = "ini";
      };
      gitDauliac = {
        sopsFile = ../dauliac/gitconfig.enc.ini;
        path = "/home/juliendauliac/.config/git/dauliac.secrets.ini";
        format = "ini";
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
      # Personal SSH key (Dauliac account)
      sshIdPerso = {
        sopsFile = ../dauliac/id_ed25519.enc;
        path = "/home/juliendauliac/.ssh/id_ed25519.perso";
        format = "binary";
      };
      sshIdPersoPub = {
        sopsFile = ../dauliac/id_ed25519.enc.pub;
        path = "/home/juliendauliac/.ssh/id_ed25519.perso.pub";
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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  programs.hyprpanel.enable = lib.mkForce false;
}
