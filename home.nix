{ config
, pkgs
, ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "dauliac";
  home.homeDirectory = "/home/dauliac/";
  xdg.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.go-task
    pkgs.direnv
    pkgs.ghq
    pkgs.silver-searcher # search
    pkgs.ncdu # Du alternative
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
    # # fonts?
    (pkgs.nerdfonts.override { fonts = [ "FiraMono" ]; })

    (pkgs.writeShellScriptBin "work" ''
      cd "$(ghq root)/$(ghq list | fzf)"
    '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  # xdg.configFile."shell/defaults".source = config.lib.file.mkOutOfStoreSymlink dotfiles/shell/defaults.bash;
  # xdg.configFile."shell/main".source = ./dotfiles/config/shell/main.sh;
  # xdg.configFile."shell" = {
  #   source = ./dotfiles/xdg-config/shell;
  #   recursive = true;
  # };
  home.file."${config.xdg.configHome}" = {
    source = ./dotfiles/xdg-config;
    recursive = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "bat";
  };

  home.shellAliases = {
    cat = "bat";
    clip = "xclip -selection c";
    restore = "trash-restore";
    rm = "trash-put";
    watch = "viddy";
    ping = "gping";
    ls = "eza";
    tree = "eza --tree";
    ps = "procs";
    df = "duf";
    du = "ncdu";
  };

  programs.home-manager.enable = true;

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      autocd = true;
      defaultKeymap = "vicmd";
      syntaxHighlighting.enable = true;

      history = {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreAllDups = true;
        ignorePatterns = [ "rm *" "pkill *" "ls *" ];
        path = "${config.xdg.dataHome}/zsh/zsh_history";
        save = 20000;
      };
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
    };
    pazi = {
      enable = true;
      enableZshIntegration = true;
    };
    tealdeer = {
      enable = true;
    };
    git = {
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
