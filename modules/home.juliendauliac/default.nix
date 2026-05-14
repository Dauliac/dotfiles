{ inputs, ... }:
let
  secretsDir = ./.;
  dauliacSecretsDir = ../home.dauliac;
in
{
  flake.modules.homeManager.user-juliendauliac =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixGlWrapper = config.systemConstants.nixgl.wrapPackage { inherit pkgs; };
      proprietaryEnabled = config.systemConstants.proprietary.enable;
    in
    let
      cimera-wrapper = pkgs.writeShellScriptBin "cimera" ''
        exec ${pkgs.nix}/bin/nix run "/home/juliendauliac/ghq/git.manomano.tech/julien.dauliac/cimera#build-cimera-rust" -- "$@"
      '';
    in
    {
      imports =
        with inputs.self.modules.homeManager;
        [
          base
          aliases
          packages
          programs-base
          secrets
          theme
          ai
          bacon
          bat
          direnv
          eza
          git
          go
          history
          kubecolor
          lazygit
          neovim
          neovim-completion
          neovim-dap
          neovim-editing
          neovim-git
          neovim-lang-devops
          neovim-lang-go
          neovim-lang-lua
          neovim-lang-misc
          neovim-lang-nix
          neovim-lang-python
          neovim-lang-rust
          neovim-lang-shell
          neovim-lang-typescript
          neovim-lang-web
          neovim-lsp
          neovim-lsp-plugins
          neovim-navigation
          neovim-opts
          neovim-packages
          neovim-ui
          pet
          pueue
          ssh
          starship
          terminal-multiplexer
          alacritty
          ghostty
          kitty
          wezterm
          tmux
          yazi
          zsh
        ]
        ++ [
          inputs.self.modules.generic.nixgl-wrapper
          inputs.self.modules.generic.proprietary-flag
        ];

      systemConstants.nixgl.wrapperType = lib.mkDefault "intel";

      targets.genericLinux.enable = true;

      xdg.systemDirs.data = [
        "/var/lib/flatpak/exports/share"
        "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
      ];

      home.sessionVariables = {
        NPM_CONFIG_PREFIX = "$XDG_DATA_HOME/npm-packages";
        PATH = "$HOME/.local/bin:$PATH:$NPM_CONFIG_PREFIX/bin/:$HOME/${config.programs.go.goBin}";
        AWS_DEFAULT_PROFILE = "manomano-support";
      };

      programs.zsh.initContent = ''
        if command -v cimera &> /dev/null; then
          eval "$(cimera activate zsh)"
        fi
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
          gh
          glab
          docker
          docker-compose
          k3d
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
          skopeo
          lazydocker
          cimera-wrapper
          pnpm_10
          pre-commit
          ruby
          just
          yq
          amazon-ecr-credential-helper
        ]
        ++ lib.optionals proprietaryEnabled [
          chromium
          dbeaver-bin
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
        core.sshCommand = "SSH_AUTH_SOCK= ssh -i ~/.ssh/id_ed25519.perso -o IdentitiesOnly=yes";
        include.path = config.sops.secrets.gitDauliac.path;
        "includeIf \"gitdir:**/*manomano*/**\"".path = config.sops.secrets.gitJulienDauliac.path;
      };

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

      programs.ssh.includes = [ "config-mm" ];

      programs.alacritty.package = nixGlWrapper pkgs.alacritty;
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
          {
            appId = "io.anytype.anytype";
            origin = "flathub";
          }
        ];
      };

      sops.secrets = {
        claude_api_key = {
          format = "yaml";
          sopsFile = ./secrets.enc.yaml;
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
          sopsFile = secretsDir + "/id_ed25519.enc";
          path = "/home/juliendauliac/.ssh/id_ed25519";
          format = "binary";
        };
        sshIdRsaPub = {
          sopsFile = secretsDir + "/id_ed25519.pub.enc";
          path = "/home/juliendauliac/.ssh/id_ed25519.pub";
          format = "binary";
        };
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

      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      programs.hyprpanel.enable = lib.mkForce false;
      programs.tofi.enable = lib.mkForce false;
      services.hyprpaper.enable = lib.mkForce false;
      wayland.windowManager.hyprland.enable = lib.mkForce false;
    };
}
