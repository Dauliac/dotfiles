# Home-manager configuration for user: juliendauliac
# Auto-imported by import-tree - no imports needed
{ lib, ... }:
let
  secretsDir = ./.;
  dauliacSecretsDir = ../home.dauliac;
in
{
  # Set GPU wrapper type for this user (non-NixOS system)
  config.dotfiles.gpu = {
    enable = true;
    wrapperType = "intel";
  };

  config.dotfiles.home.userModules.juliendauliac = lib.mkAfter [
    (
      {
        config,
        lib,
        pkgs,
        nixGlWrapper,
        proprietaryEnabled,
        ...
      }:
      {
        # Enable generic Linux target for non-NixOS systems (Ubuntu)
        targets.genericLinux.enable = true;

        # Add flatpak paths to XDG data dirs (complements xdg.systemDirs.data from shared config)
        xdg.systemDirs.data = [
          "/var/lib/flatpak/exports/share"
          "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
        ];

        home.sessionVariables = {
          NPM_CONFIG_PREFIX = "$XDG_DATA_HOME/npm-packages";
          PATH = "$HOME/ghq/git.manomano.tech/julien.dauliac/ezci/cli/target/release:$PATH:$NPM_CONFIG_PREFIX/bin/:$HOME/${config.programs.go.goBin}";
          AWS_DEFAULT_PROFILE = "manomano-support";
        };

        programs.zsh.initContent = ''
          if command -v ezci &> /dev/null; then
            eval "$(ezci activate zsh)"
          fi

          # export ANTHROPIC_API_KEY="$(cat ${config.sops.secrets.claude_api_key.path})"
        '';

        programs.mise = {
          enable = true;
          enableZshIntegration = true;
        };

        home.packages =
          with pkgs;
          [
            awscli2
            cloudflared
            cloudlens
            fluxcd
            glab
            docker
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
            pre-commit
            ruby
            just
            vector
            yq
            ansible
            minio-client
            amazon-ecr-credential-helper
            (nixGlWrapper prismlauncher)
          ]
          ++ lib.optionals proprietaryEnabled [
            # Proprietary software
            google-chrome
            slack
            dbeaver-bin
            jetbrains.goland
            jetbrains.pycharm
            gemini-cli-bin
          ];

        home.shellAliases = {
          vault_all = ''
            for ENV in int stg prd support ist; do
              export VAULT_ADDR=https://vault-eu-west-3.$ENV.manomano.com
              export VAULT_''${ENV}_TOKEN=$(vault login -token-only -path=sso -method=oidc role=sre | grep hvs)
            done'';
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
          packages = lib.optionals proprietaryEnabled [
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
            claude_api_key = {
              format = "yaml";
              sopsFile = ./secrets.enc.yaml;
            };
            aws = {
              sopsFile = secretsDir + "/aws-config.enc.toml";
              path = "/home/juliendauliac/.aws/config";
              format = "binary";
            };
            gitJulienDauliacRoot = {
              sopsFile = secretsDir + "/gitconfig.root.enc.ini";
              path = "/home/juliendauliac/.gitconfig";
              format = "ini";
            };
            gitJulienDauliac = {
              sopsFile = secretsDir + "/gitconfig.enc.ini";
              path = "/home/juliendauliac/.config/git/juliendauliac.secrets.ini";
              format = "ini";
            };
            gitDauliac = {
              sopsFile = dauliacSecretsDir + "/gitconfig.enc.ini";
              path = "/home/juliendauliac/.config/git/dauliac.secrets.ini";
              format = "ini";
            };
            sshIdRsa = {
              sopsFile = secretsDir + "/id_rsa.enc";
              path = "/home/juliendauliac/.ssh/id_rsa";
              format = "binary";
            };
            sshIdRsaPub = {
              sopsFile = secretsDir + "/id_rsa.enc.pub";
              path = "/home/juliendauliac/.ssh/id_rsa.pub";
              format = "binary";
            };
            # Personal SSH key (Dauliac account)
            sshIdPerso = {
              sopsFile = dauliacSecretsDir + "/id_ed25519.enc";
              path = "/home/juliendauliac/.ssh/id_ed25519.perso";
              format = "binary";
            };
            sshIdPersoPub = {
              sopsFile = dauliacSecretsDir + "/id_ed25519.enc.pub";
              path = "/home/juliendauliac/.ssh/id_ed25519.perso.pub";
              format = "binary";
            };
            glab = {
              sopsFile = secretsDir + "/glab-config.enc";
              path = "/home/juliendauliac/.config/glab-cli/config.yml";
              format = "binary";
            };
            ovpn_client_ca = {
              sopsFile = secretsDir + "/openvpn/ca.enc.crt";
              path = "/home/juliendauliac/.config/openvpn/client/ca.crt";
              format = "binary";
            };
            ovpn_client_cert = {
              sopsFile = secretsDir + "/openvpn/client.enc.crt";
              path = "/home/juliendauliac/.config/openvpn/client09202.crt";
              format = "binary";
            };
            ovpn_client_key = {
              sopsFile = secretsDir + "/openvpn/client.enc.key";
              path = "/home/juliendauliac/.config/openvpn/client/client09202.key";
              format = "binary";
            };
            ovpn_client_config = {
              sopsFile = secretsDir + "/openvpn/client.enc.ovpn";
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
    )
  ];
}
