{ pkgs, ... }: {
  programs.home-manager.enable = true;

  home.packages = [
    pkgs.direnv
    pkgs.ghq
    pkgs.silver-searcher
    pkgs.zellij
    pkgs.fzf
    pkgs.git
    pkgs.delta
    pkgs.bat
    pkgs.exa
    pkgs.starship
    pkgs.go-task
  ];

  programs.git = {
    enable = true;
    includes = [
      { path = "~/.gitlocalconfig"; }
    ];
    aliases = {
      ap = "add -p";
    };
    extraConfig = {
      pull.ff = "only";
    };
  };
}
