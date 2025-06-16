{ config, ... }:
{
  programs.git = {
    enable = true;
    userName = config.home.username;
    lfs = {
      enable = true;
    };
    aliases = {
      convco = "!GIT_EDITOR='convco commit' git commit";
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
      red = "gamble --red";
      green = "gamble --green";
      refactor = "gamble --refactor";
      rede = "gamble --red --edit";
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
      core = {
        editor = "nvim";
      };
      push = {
        autoSetupRemote = true;
        default = "current";
      };
      status = {
        showUntrackedFiles = "all";
        submoduleSummary = true;
      };
      absorb = {
        maxStack = 60;
        oneFixupPerCommit = true;
      };
    };
  };
}
