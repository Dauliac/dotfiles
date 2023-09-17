{ config
, pkgs
, ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "dauliac";
  home.homeDirectory = "/home/dauliac";
  xdg.cacheHome = "/home/dauliac/.local/cache/";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.go-task
    pkgs.direnv
    pkgs.git
    pkgs.git
    pkgs.ghq
    pkgs.silver-searcher # search
    pkgs.zellij # terminal multiplexer
    pkgs.fzf # fuzzy finder
    pkgs.delta # diff alternative
    pkgs.bat # cat alternative
    pkgs.eza # ls alternative
    pkgs.starship # Prompt
    pkgs.ncdu # Du alternative
    pkgs.duf # df alternative
    pkgs.fd # find alternative
    pkgs.viddy # watch alternative
    pkgs.gping # ping alternative
    pkgs.procs # ps alternative
    pkgs.hyperfine # benchmarking
    pkgs.broot # tree alternative
    pkgs.tealdeer # Documentation
    pkgs.dog # dig alternative
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    (pkgs.nerdfonts.override { fonts = [ "FiraMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
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
  # home.file = {
  # ".zprofile".source = dotfiles/profile.sh;
  # ".profile".source = config.lib.file.mkOutOfStoreSymlink dotfiles/profile;

  # xdg.configFile."shell/defaults.bash".source = ./dotfiles/shell/defaults.bash;

  # # You can also set the file content immediately.
  # ".gradle/gradle.properties".text = ''
  #   org.gradle.console=verbose
  #   org.gradle.daemon.idletimeout=3600000
  # '';
  # };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/dauliac/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
