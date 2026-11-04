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

      # xi sources: 3-way reconciliation (working dir / sources dir /
      # remote) for this checkout. `remote` is the real GitHub remote -
      # the same one `xi system switch` already uses for the real
      # system-manager deployment - so `sources dir` tracks an
      # independent, shared source of truth. `workingDir` is this local
      # checkout, so `xi home sources status|diff|sync` can run the
      # ahead/behind/diverged matrix (crates/xi-core/src/sources/conflict.rs)
      # between what's on GitHub, what xi last fetched, and what you're
      # actually editing. Pointing `remote` at the local path instead
      # (tempting, avoids the push round-trip) would collapse that: if
      # `remote` and `workingDir` are the same directory, sources dir
      # just mirrors your own commits back at you and the matrix can
      # never catch a genuinely independent push. `gitops.enable` is
      # deliberately left off: this host's home-manager is already
      # driven by system-manager (modules/flake/system-configurations.nix),
      # and a second, user-scope auto-activator here would race it - the
      # exact failure mode xi-sources-race exists to avoid. Toggle it on
      # only if you stop routing home-manager through system-manager on
      # this host.
      programs.xi.sources = {
        enable = true;
        remote = "git@github.com:Dauliac/dotfiles.git";
        branch = "master";
        workingDir = "/home/juliendauliac/ghq/github.com/Dauliac/dotfiles";
      };

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
      # Settings scope is the thing that is easy to get wrong here, and
      # it fails silently: git_companion's tunables are plugin-level, so
      # they go in `plugin_settings."tphilippot/git_companion"`, NOT
      # `widget.git_companion`. Long note at that attrset below.
      #
      # glab's own config (host, token) is deliberately NOT managed here
      # - another tool owns ~/.config/glab-cli/config.yml. We only READ
      # it, via the ExecStart wrapper below, to learn which instance to
      # talk to. See that wrapper for why the plugin needs the hint.
      #
      # `hy4ri/herdr` is kept manomano-local for now because the work laptop
      # is where coding-agent sessions actually run; personal hosts can opt in
      # later by moving the block into the shared plugins/bar modules. The
      # `herdr` binary dependency is already on PATH via the llm-agents input.
      # Wire the self-hosted anytype-noctalia Noctalia plugin on this
      # host.  Guarded by the opt-in option declared in
      # modules/home-manager/desktop/noctalia/anytype.nix because the
      # module declares `sops.secrets.anytype_api_key`, which fails
      # activation on hosts that have not yet added the key to
      # secrets.yaml.  Enabled here: this host owns the key.
      myNoctalia.anytype.enable = true;

      # ICS calendar (sops key `calendar_url` in root secrets.yaml) is
      # work-laptop-only  -  the URL points at the corp calendar, so
      # personal hosts have nothing to display and would fail activation
      # with a missing sops key. See modules/home-manager/desktop/noctalia/calendar.nix.
      myNoctalia.calendar.enable = true;

      # Teach the noctalia service which GitLab instance `glab` should
      # talk to, by asking glab itself.
      #
      # Why this is needed: git_companion's service shells out to
      # `glab mr list` from the service's cwd, which has no git remote.
      # glab resolves its instance as GITLAB_HOST -> the global `host`
      # config key -> the cwd's git remote -> gitlab.com. The `hosts:`
      # map in ~/.config/glab-cli/config.yml is only a credential store
      # keyed BY hostname; glab never promotes a lone entry there into a
      # default. So with no `host:` key and no remote to infer from,
      # every call went to gitlab.com and 401'd.
      #
      # Rather than duplicate the hostname here (it is corp-internal, and
      # another tool owns that config file), derive it at service start
      # from glab's own authenticated-host list. Single source of truth,
      # read-only, and nothing corp-specific lands in the Nix store.
      #
      # Two traps worth spelling out, both hit on the way here:
      #
      #   - Use mise's glab, NOT `pkgs.glab`. mise owns glab on this box
      #     and ships 1.124.0, while nixpkgs is back on 1.99.0, which has
      #     no `--all` / `--output json` on `auth status` at all ("Unknown
      #     flag: --output"). Prepending the shims dir also means the
      #     plugin's own `glab mr list` calls resolve to the same modern
      #     binary instead of whatever a bare service PATH turns up. The
      #     shim path is version-stable; the real install path is not.
      #   - `--output json` is required, not cosmetic. The human-readable
      #     `glab auth status` prints its host list to STDERR, so command
      #     substitution captures an empty string and the export silently
      #     no-ops. The JSON form goes to stdout.
      #
      # If glab is ever downgraded below the JSON flags, `host` comes back
      # empty and we leave GITLAB_HOST unset rather than exporting junk -
      # the widget then shows an error glyph instead of lying.
      #
      # head -1 picks the first successfully-authenticated host; if this
      # box ever logs into two instances, pin GITLAB_HOST explicitly.
      systemd.user.services.noctalia.Service.ExecStart = lib.mkForce (
        toString (
          pkgs.writeShellScript "noctalia-glab-host" ''
            export PATH="$HOME/.local/share/mise/shims:$PATH"
            host=$(glab auth status --all --output json \
              --jq '.hosts[] | select(.state=="success") | .host' 2>/dev/null | head -1)
            if [ -n "$host" ]; then
              export GITLAB_HOST="$host"
            fi
            exec /usr/bin/noctalia
          ''
        )
      );

      programs.noctalia.settings = {
        plugins.enabled = lib.mkAfter [
          "tphilippot/git_companion"
          "hy4ri/herdr"
        ];
        # Widget-instance table. ONLY `type` belongs here: it binds the
        # `git_companion` name used in `bar.main.end` to the plugin's
        # widget entrypoint. Every tunable lives in `plugin_settings`
        # below - see the scope note there before adding a key here.
        widget.git_companion = {
          type = "tphilippot/git_companion:widget";
        };
        # herdr declares display_mode / hide_count_when_zero /
        # hide_agentless_panes as `[[widget.setting]]`, so unlike
        # git_companion they genuinely belong in the widget table.
        # (Its one plugin-level `[[setting]]`, show_other_machines, would
        # go under plugin_settings - we leave it at its default.)
        widget.herdr = {
          type = "hy4ri/herdr:bar";
          display_mode = "icon_and_count";
          hide_count_when_zero = true;
          hide_agentless_panes = true;
        };

        # Plugin-level settings table, keyed by the FULL plugin id
        # (author prefix included - `noctalia config validate` rejects a
        # bare "git_companion" with "no loaded plugin with this id").
        #
        # Why these are not under `widget.git_companion`: a plugin.toml
        # declares settings at two scopes, and noctalia routes them to
        # two different config tables.
        #
        #   [[setting]]          -> plugin_settings."<author>/<id>"
        #   [[widget.setting]]   -> widget.<instance>
        #
        # git_companion declares ALL of its settings as top-level
        # `[[setting]]` and has ZERO `[[widget.setting]]`, so everything
        # it reads via `noctalia.getConfig(...)` must live here. Keys put
        # in the widget table are silently ignored and the plugin falls
        # back to its plugin.toml defaults - which means `platform`
        # reverts to "github" and the bar shows a GitHub glyph with no
        # data. bongocat is the opposite case (all `[[widget.setting]]`),
        # which is why its block looks different; check the plugin.toml
        # scope before adding settings for any new plugin, and run
        # `noctalia config validate` - it flags every misplaced key as
        # "unknown setting".
        plugin_settings."tphilippot/git_companion" = {
          platform = "gitlab";
          # GitLab scope. `service.luau` hard-fails with
          # "gitlab_scope_missing" when both `group` and `repo` are empty,
          # because the unscoped `glab mr list` needs a git-repo cwd and
          # the service runs from an arbitrary one. So some scope is
          # mandatory; `group` is a single string, not a list.
          #
          # Caveat: authored/assigned MRs actually span ~8 top-level
          # groups (platform-engineering is larger than pulse), and the
          # instance has 199 roots with no common ancestor, so no single
          # value covers everything. Watching all of GitLab would need a
          # patched plugin driving `glab api merge_requests?scope=...`
          # instead of `glab mr list --group`.
          group = "pulse";
          refresh_interval = 60;
          bar_display_mode = "both";
          show_prs = true;
          show_issues = true;
          show_reviews = true;
          count_reviews_with_prs = true;
          # GitLab-only notifications. Each fires when a MR *I authored*
          # transitions INTO the matching detailed_merge_status; the first
          # fetch after service start only records state, so nothing
          # replays at login. Routes through the shared notification daemon
          # (modules/home-manager/desktop/noctalia/notification.nix:
          # `enable_daemon = true`). Full table in the git_companion
          # README.md "Notifications" section.
          notify_mr_mergeable = true;
          notify_mr_pipeline_failed = true;
          notify_mr_conflict = true;
          notify_mr_changes_requested = true;
        };
        # Override the shared end list (modules/home-manager/desktop/noctalia/bar.nix)
        # with lib.mkForce because we want git_companion + herdr slotted BETWEEN
        # media and tray, not appended at the tail - lib.mkAfter only appends.
        #
        # github_prs must be repeated here: the shared list carries it, but
        # mkForce replaces that list wholesale rather than merging into it,
        # so anything omitted here silently disappears from this host's bar.
        # The two companions sit side by side - github_prs (GitHub, via gh)
        # then git_companion (corp GitLab, via glab).
        bar.main.end = lib.mkForce [
          "media"
          "github_prs"
          "git_companion"
          "herdr"
          "tray"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "session"
        ];
      };
    };
}
