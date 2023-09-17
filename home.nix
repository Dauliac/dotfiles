{ config
, pkgs
, ...
}: {
  home.username = "dauliac";
  home.homeDirectory = "/home/dauliac/";
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
    pkgs.eza # TODO: check how to upgrade home-manager to use eza configs
    pkgs.k9s # kubernetes client
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
  };
  home.shellAliases = {
    cat = "bat";
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
  };
  programs.home-manager.enable = true;
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      autocd = true;
      # defaultKeymap = "vicmd";
      syntaxHighlighting.enable = true;
      history = {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreAllDups = true;
        ignorePatterns = [ "rm *" "pkill *" "ls *" ];
        path = "${config.xdg.dataHome}/zsh/zsh_history";
        save = 20000;
      };
      prezto = {
        enable = true;
        autosuggestions.color = "fg=blue";
        editor.keymap = "vi";
        ssh.identities = [
          "id_rsa"
          "id_dsa"
        ];
        syntaxHighlighting = {
          highlighters = [
            "main"
            "brackets"
            "pattern"
            "line"
            "cursor"
            "root"
          ];
          styles = {
            builtin = "bg=blue";
            command = "bg=blue";
            function = "bg=blue";
          };

          pattern = {
            "rm*-rf*" = "fg=white,bold,bg=red";
          };
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
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    pazi = {
      enable = true;
      enableZshIntegration = true;
    };
    tealdeer = {
      enable = true;
    };
    git = {
      enable = true;
      aliases = {
        st = "status - sb";
        br = "branch -a";
        co = "checkout";
        l = "log --graph --decorate --pretty=oneline --abbrev-commit";
        ls = "ls-files";
        lg = "log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        unstage = "reset --";
        rollback = "reset HEAD~";
        alias = "config --get-regexp alias";
        rewrite = "!git commit --amend --no-edit && git push --force-with-lease";
        rewrite-all = "!git add . && git rewrite";
      };
      delta = {
        enable = true;
      };
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
        commit = {
          template = "${config.xdg.configHome}/git/commit-template";
        };
      };
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
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
  };
}
