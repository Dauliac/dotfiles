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
    {
      imports =
        with inputs.self.modules.homeManager;
        [
          user-juliendauliac-corp
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
          lazyjira
          kubecolor
          lazygit
          xi
          neovim
          neovim-packages
          sine
          herdr
          pet
          try
          pueue
          starship
          dolt-beads
          beads-config
          desktop
          niri
          noctalia
          netbird-tray
          alacritty
          ghostty
          kitty
          wezterm
          tmux
          yazi
          zsh
        ]
        ++ [
          # nixgl-wrapper is imported transitively via the `niri` module.
          inputs.self.modules.generic.proprietary-flag
          inputs.self.modules.generic.ssh-keys
          inputs.aws-nix-cache.homeManagerModules.default
        ];

      programs.nixvim.imports = with inputs.self.modules.nixvim; [
        base
        completion
        dap
        editing
        git
        lang-devops
        lang-go
        lang-lua
        lang-misc
        lang-nix
        lang-python
        lang-rust
        lang-shell
        lang-typescript
        lang-web
        lsp
        lsp-plugins
        navigation
        opts
        ui
      ];

      # ML-PF603JJ8 (successor to ML-PF59GCGW) has an AMD Radeon iGPU and
      # runs niri via DankLinux's apt package — see systemConstants.nixgl
      # description. If you ever come back to a pure nix-managed niri
      # on this user, flip to "mesa" (AMD) or "intel" (older laptop).
      systemConstants.nixgl.wrapperType = lib.mkDefault "system";

      systemConstants.ssh.keys = {
        personal.filename = "id_ed25519.perso";
        corp.filename = "id_ed25519";
      };

      targets.genericLinux.enable = true;

      xdg.systemDirs.data = [
        "/var/lib/flatpak/exports/share"
        "${config.home.homeDirectory}/.local/share/flatpak/exports/share"
      ];

      home.sessionVariables = {
        NPM_CONFIG_PREFIX = "$XDG_DATA_HOME/npm-packages";
      };

      # Use home.sessionPath (home-manager's official mechanism) instead of
      # rewriting PATH via sessionVariables — that overwrote $PATH and dropped
      # /nix/var/nix/profiles/default/bin because targets.genericLinux only
      # exposes ~/.nix-profile/bin, not the default profile.
      home.sessionPath = [
        "$HOME/.local/bin"
        "$NPM_CONFIG_PREFIX/bin"
        "$HOME/go/bin"
        "/nix/var/nix/profiles/default/bin"
        # Flatpak app launcher shims. Debian's flatpak.deb also drops a
        # /etc/profile.d/flatpak.sh with the same paths, but home-manager's
        # session env is written before /etc/profile.d fully sources on
        # some login paths (TTY1 + zsh login shell in particular), so we
        # pin them here too.
        "/var/lib/flatpak/exports/bin"
        "$HOME/.local/share/flatpak/exports/bin"
      ];

      home.packages =
        with pkgs;
        [
          # flatpak: the CLI in $PATH so `flatpak run …`, `flatpak list`, etc.
          # work interactively. nix-flatpak's HM systemd service uses its own
          # absolute store path for the install step, so this is purely for
          # user-invoked commands.
          flatpak
          awscli2
          cloudflared
          gh
          glab
          docker_29
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
          dive
          python312
          python313Packages.virtualenv
          terraform
          terragrunt
          vault
          vsh
          skopeo
          lazydocker
          pnpm_11
          pre-commit
          ruby
          just
          yq
          amazon-ecr-credential-helper
          datadog-pup
          libreoffice
        ]
        ++ lib.optionals proprietaryEnabled [
          chromium
          dbeaver-bin
          gemini-cli-bin
        ];

      # `vault_all` and `AWS_DEFAULT_PROFILE` are corp-sensitive — the
      # actual endpoint template + profile name live in `corp.nix`
      # under sops.templates and are sourced from zsh at shell init.
      programs.zsh.initExtra = ''
        [ -r "${config.sops.templates."corp/vault-alias.sh".path}" ] \
          && source "${config.sops.templates."corp/vault-alias.sh".path}"
      '';

      # Two [include] entries: dauliac static ini + corp `includeIf` ini
      # (the glob string is corp-sensitive so it lives in a sops template
      # — see corp.nix / "corp/gitconfig-includes.ini"). Uses `.includes`
      # (a list) because `programs.git.settings.include.path` is a single
      # attribute and would collide.
      programs.git.includes = [
        { inherit (config.sops.secrets.gitDauliac) path; }
        { inherit (config.sops.templates."corp/gitconfig-includes.ini") path; }
      ];

      programs.git.settings = {
        # pushInsteadOf (not insteadOf) so `git push` uses ssh, but
        # anonymous clone/fetch stay on https. Otherwise user daemons
        # that clone from github (e.g. noctalia's plugin catalog) hit
        # "Host key verification failed" because their systemd unit
        # has no TTY / ssh-askpass.
        "url \"ssh://git@github.com/\"".pushInsteadOf = "https://github.com/";
      };

      # SSH-side per-host key selection replaces git's core.sshCommand /
      # includeIf.gitdir. The gitdir predicate only matches when the git
      # worktree path contains the corp glob, which breaks for tooling
      # that fetches from a cache mirror outside the repo tree (e.g.
      # `copier recopy` cloning through ~/.cache/copier/git/*.git). ssh
      # selects by hostname, so it works regardless of where .git lives.
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "github.com" = {
            identityFile = "~/.ssh/${config.systemConstants.ssh.keys.personal.filename}";
            identitiesOnly = true;
          };
          # Corp GitLab matchBlock + hand-managed bastion Include live in
          # a sops-rendered ssh_config fragment; see corp.nix / template
          # "corp/ssh-config".
          "*" = {
            extraOptions = {
              Include = config.sops.templates."corp/ssh-config".path;
            };
          };
        };
      };

      programs.alacritty.package = nixGlWrapper pkgs.alacritty;
      programs.kitty.package = nixGlWrapper pkgs.kitty;

      services.flatpak = {
        enable = true;
        # Declare flathub so the very first activation on a fresh box
        # doesn't need a manual `flatpak remote-add` first. nix-flatpak's
        # HM service creates the remote in the user's flatpak profile
        # (~/.local/share/flatpak) before running the install step.
        remotes = [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
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
          {
            appId = "org.signal.Signal";
            origin = "flathub";
          }
        ];
        # Force native Wayland for all flatpaks. Flathub defaults Vesktop to
        # XWayland "for compatibility", which routes screencast through XWayland
        # and breaks on niri. Dropping x11 sockets makes the sandbox negotiate
        # wayland + xdg-desktop-portal ScreenCast directly.
        overrides = {
          global = {
            Context.sockets = [
              "wayland"
              "!x11"
              "!fallback-x11"
            ];
          };
        };
      };

      sops.secrets = {
        claude_api_key = {
          format = "yaml";
          sopsFile = ./secrets.enc.yaml;
        };
        atlassian_api_token = {
          # Consumed by modules/home-manager/programs/gojira.nix — the
          # gojira wrapper pipes this secret into `gojira` on every call.
          # Rotate at https://id.atlassian.com/manage-profile/security/api-tokens
          # then `sops modules/home.juliendauliac/secrets.enc.yaml` +
          # `xi home switch .`.
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
        doltJulienDauliac = {
          sopsFile = secretsDir + "/dolt.config.enc.json";
          path = "/home/juliendauliac/.dolt/config_global.json";
          format = "binary";
        };
        sshIdRsa = {
          sopsFile = secretsDir + "/id_ed25519.enc";
          path = "${config.home.homeDirectory}/.ssh/${config.systemConstants.ssh.keys.corp.filename}";
          format = "binary";
        };
        sshIdRsaPub = {
          sopsFile = secretsDir + "/id_ed25519.pub.enc";
          path = "${config.home.homeDirectory}/.ssh/${config.systemConstants.ssh.keys.corp.publicFilename}";
          format = "binary";
        };
        sshIdPerso = {
          sopsFile = dauliacSecretsDir + "/id_ed25519.enc";
          path = "${config.home.homeDirectory}/.ssh/${config.systemConstants.ssh.keys.personal.filename}";
          format = "binary";
        };
        sshIdPersoPub = {
          sopsFile = dauliacSecretsDir + "/id_ed25519.enc.pub";
          path = "${config.home.homeDirectory}/.ssh/${config.systemConstants.ssh.keys.personal.publicFilename}";
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

      services.aws-nix-cache = {
        enable = true;
        package = inputs.aws-nix-cache.packages.${pkgs.system}.default;
        awsProfile = "corp"; # corp AWS profile alias; the real name is
        # sourced from sops (see AWS_DEFAULT_PROFILE in corp/vault-alias.sh).
        # aws-nix-cache also honours AWS_PROFILE from the environment.
      };

      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      home.activation.postBuildHooks = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        run ${pkgs.fontconfig}/bin/fc-cache -f
      '';

      programs.hyprpanel.enable = lib.mkForce false;
      services.hyprpaper.enable = lib.mkForce false;
      wayland.windowManager.hyprland.enable = lib.mkForce false;

      # Work-laptop-only: Noctalia Git Companion bar widget (community plugin
      # `tphilippot/git_companion`) scoped to the corp GitLab via `glab`, which
      # is already in `home.packages` above and authenticated through the
      # existing corp OAuth flow. The shared noctalia module (plugins.nix /
      # bar.nix) stays glab-free so personal hosts (dauliac, gary) don't fetch
      # anything they can't authenticate.
      #
      # `hy4ri/herdr` is kept manomano-local for now because the work laptop
      # is where coding-agent sessions actually run; personal hosts can opt in
      # later by moving the block into the shared plugins/bar modules. The
      # `herdr` binary dependency is already on PATH via the llm-agents input.
      programs.noctalia.settings = {
        plugins.enabled = lib.mkAfter [
          "tphilippot/git_companion"
          "hy4ri/herdr"
        ];
        widget.git_companion = {
          type = "tphilippot/git_companion:widget";
          platform = "gitlab";
          bar_display_mode = "both";
          show_reviews = true;
          count_reviews_with_prs = true;
        };
        widget.herdr = {
          type = "hy4ri/herdr:bar";
          display_mode = "icon_and_count";
          hide_count_when_zero = true;
          hide_agentless_panes = true;
        };
        bar.main.end = lib.mkAfter [
          "git_companion"
          "herdr"
        ];
      };
    };
}
