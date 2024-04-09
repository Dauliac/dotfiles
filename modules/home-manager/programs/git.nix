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
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519";
      push = {
        autoSetupRemote = true;
        default = "current";
      };
      commit = {
        gpgsign = true;
        template = "${config.xdg.configHome}/git/commit-template";
      };
      #TODO: add include per server:
      # includes = [
      #   https://nix-community.github.io/home-manager/options.xhtml#opt-programs.git.includes._.condition
      #   {
      #     condition = {};
      #     path = "~/.config/git/secret";
      #   }
      #   {
      #     path = "~/.config/git/secret";
      #   }
      # ];
    };
  };
}
