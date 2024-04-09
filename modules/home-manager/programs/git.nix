{ config, ... }: {
  programs.git = {
    enable = true;
    userName = config.home.username;
    aliases = {
      st = "status -sb";
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
      rb = "!git fetch --all; git rebase";
    };
    difftastic = {
      enable = true;
    };
    ignores = [
      ".*.swp"
      "*.ova"
      "*.zip"
      "*.tgz"
      "*.tar.gz"
      "*.img"
      "*.iso"
    ];
    extraConfig = {
      core = { editor = "nvim"; };
      commit = { template = "${config.xdg.configHome}/git/commit-template"; };
    };
  };
}
