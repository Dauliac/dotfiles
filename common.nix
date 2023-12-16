{ config, pkgs, ... }: {
  # home.username = "dauliac";
  # home.homeDirectory = "/home/dauliac/";
  xdg.enable = true;
  home.stateVersion = "23.05"; # Please read the comment before changing.
  home.packages = [
    pkgs.go-task
    pkgs.ghq
    pkgs.silver-searcher # search
    pkgs.ncdu # du alternative
    pkgs.duf # df alternative
    pkgs.fd # find alternative
    pkgs.viddy # watch alternative
    pkgs.gping # ping alternative
    pkgs.procs # ps alternative
    pkgs.hyperfine # benchmarking
    pkgs.dog # dig alternative
    pkgs.trash-cli # shell trash
    pkgs.systemctl-tui # Cool tui
    pkgs.speedtest-go # network speed test
    pkgs.eza # TODO: check how to upgrade home-manager to use eza configs
    (pkgs.nerdfonts.override { fonts = [ "FiraMono" ]; })
  ];
  home.file."${config.xdg.configHome}" = {
    source = ./dotfiles/xdg-config;
    recursive = true;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "bat";
    DIRENV_LOG_FORMAT = ""; # NOTE: disable direnv log
    DIRENV_WARN_TIMEOUT = "80s";
    MCFLY_PROMPT = "❯";
  };
  home.shellAliases = {
    cat = "bat";
    nvim =
      "nix run $(${pkgs.ghq}/bin/ghq root)/$(${pkgs.ghq}/bin/ghq list | grep Dauliac/neovim)";
    clip = "xclip -selection c";
    restore = "trash-restore";
    rm = "trash-put";
    watch = "viddy";
    ping = "gping";
    ls = "eza";
    ll = "ls -la";
    tree = "eza --tree";
    ps = "procs";
    c = "clear";
    df = "duf";
    du = "ncdu";
    work = "cd $(ghq root)/$(ghq list | fzf)";
    speedtest = "speedtest-go";
  };
  xdg = {
    desktopEntries = {
      wezterm = {
        name = "Wezterm";
        genericName = "Terminal";
        exec =
          "nix run --impure github:guibou/nixGL -- ${pkgs.wezterm}/bin/wezterm";
      };
    };
  };
  programs.home-manager.enable = true;
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      autocd = true;
      syntaxHighlighting.enable = true;
      profileExtra = ''
        export XDG_SECRET_HOME="''${XDG_CONFIG_HOME}/secrets"
        # Source all files into XDG_SECRET_HOME
        source <(cat ''${XDG_SECRET_HOME:?}/*)

        # NOTE: this enable CTRL+e to eddit current command line
        autoload edit-command-line
        zle -N edit-command-line
        bindkey -M vicmd e edit-command-line
      '';
      history = {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreAllDups = true;
        ignorePatterns = [ "rm *" "pkill *" "ls *" ];
        path = "${config.xdg.dataHome}/zsh/zsh_history";
        save = 20000;
        share = true;
      };
      prezto = {
        enable = true;
        autosuggestions.color = "fg=blue";
        editor.keymap = "vi";
        ssh.identities = [ "id_rsa" "id_dsa" ];
        syntaxHighlighting = {
          highlighters = [ "main" "brackets" "pattern" "line" "cursor" "root" ];
          styles = {
            builtin = "bg=blue";
            command = "bg=blue";
            function = "bg=blue";
          };

          pattern = { "rm*-rf*" = "fg=white,bold,bg=red"; };
        };
        pmodules = [
          "environment"
          "terminal"
          "editor"
          "history"
          "directory"
          "spectrum"
          "utility"
          "completion"
        ];
      };
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red) ";
          vicmd_symbol = "[V](bold green) ";
        };
        cmd_duration = { min_time = 500; };
        git_branch = { symbol = "🌱 "; };

        git_state = {
          cherry_pick = "[🍒 PICKING](bold red)";
          merge = "[🔀 MERGE](bold red)";
        };

        git_commit = {
          commit_hash_length = 4;
          tag_symbol = "🔖 ";
        };
      };
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    # NOTE: fast cd
    pazi = {
      enable = true;
      enableZshIntegration = true;
    };
    # NOTE: cheat sheet
    tealdeer = { enable = true; };
    # NOTE: cheat sheet
    navi = {
      enable = true;
      enableZshIntegration = true;
    };
    pet = {
      enable = true;
      snippets = [
        {
          command = "docker system prune -a -f; nix-store -gc; trash-empty";
          description = "Clean docker, nix, and trash";
          tag = [ "docker" "nix" "trash" ];
        }
        {
          command = "git rebase -i HEAD~10";
          description = "Rewrite 10 last commits";
          tag = [ "git" "history" ];
        }
        {
          command =
            "ls $(nix build 'nixpkgs#typescript' --print-out-paths --no-link)";
          tag = [ "nix" "package" ];
        }
      ];
    };
    git = {
      enable = true;
      aliases = {
        st = "\n            status - sb ";
        br = "\n            branch - a ";
        co = "\n            checkout ";
        l =
          "\n            log - -graph - -decorate - -pretty=oneline --abbrev-commit";
        ls = "ls-files";
        lg =
          "log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        unstage = "reset --";
        rollback = "reset HEAD~";
        alias = "config --get-regexp alias";
        rewrite =
          "!git commit --amend --no-edit && git push --force-with-lease";
        rewrite-all = "!git add . && git rewrite";
      };
      delta = { enable = true; };
      ignores = [
        "node_modules/"
        ".*.swp"
        ".*.un~"
        ".vagrant"
        "vendor"
        "*.pyc"
        "__pycache__"
        "venv/"
        "*.ova"
        "*.zip"
        "*.tgz"
        "*.tar.gz"
        "*.rkestate"
        "*.img"
        "*.iso"
      ];
      extraConfig = {
        core = { editor = "nvim"; };
        commit = { template = "${config.xdg.configHome}/git/commit-template"; };
      };
    };
    # fzf = {
    #   enable = true;
    #   enableZshIntegration = true;
    # };
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "ansi";
        style = "numbers,changes,header";
        map-syntax = [
          # NOTE: use C++ syntax highlighting for header files
          "h:cpp"
          # NOTE: use "gitignore" highlighting for ".ignore" files
          ".ignore:.gitignore"
        ];
      };
    };
    zellij = {
      enable = true;
      enableZshIntegration = true;
    };
    # TODO: fix this
    # eza = {
    #   enable = true;
    #   enableAliases = true;
    #   git = true;
    #   icons = true;
    # };
    htop = { enable = true; };
    wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = ''
        local
        wezterm = require 'wezterm';

        wezterm.on('user-var-changed', function(window, pane, name, value)
            local overrides = window:get_config_overrides() or {}
            if name == "ZEN_MODE" then
                local incremental = value:find("+")
                local number_value = tonumber(value)
                if incremental ~= nil then
                    while (number_value > 0) do
                        window:perform_action(wezterm.action.IncreaseFontSize, pane)
                        number_value = number_value - 1
                    end
                    overrides.enable_tab_bar = false
                elseif number_value < 0 then
                    window:perform_action(wezterm.action.ResetFontSize, pane)
                    overrides.font_size = nil
                    overrides.enable_tab_bar = true
                else
                    overrides.font_size = number_value
                    overrides.enable_tab_bar = false
                end
            end
            window:set_config_overrides(overrides)
        end)

        return {
          color_scheme = "Gruvbox Dark (Gogh)",

          window_background_opacity = 0.89,
          font = wezterm.font(
            "FiraCode Nerd Font Mono",
            {bold=false, weight = "Regular", stretch = "Normal", italic = false}
          ),
          default_cursor_style = "SteadyBar",
          hide_tab_bar_if_only_one_tab = true,
        }
      '';
    };
    jq = { enable = true; };
    k9s = { enable = true; };
    mcfly = {
      enable = true;
      enableZshIntegration = true;
      keyScheme = "vim";
      fuzzySearchFactor = 5;
    };
  };
}
