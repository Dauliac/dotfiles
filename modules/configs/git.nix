{ config, pkgs, ... }: {
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
    rewrite = "!git commit --amend --no-edit && git push --force-with-lease";
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
}
