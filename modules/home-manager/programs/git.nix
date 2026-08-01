{
  flake.modules.homeManager.git = {
    programs.difftastic = {
      enable = true;
      git.enable = true;
    };
    programs.git = {
      enable = true;
      lfs.enable = true;
      settings.alias = {
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
      ignores = [
        ".*.swp"
        "*.ova"
        "*.zip"
        "*.tgz"
        "*.tar.gz"
        "*.img"
        "*.iso"
        ".claude/settings.local.json"
        "_bmad"
        "_bmad-output"
        # Coding-agent state dirs created per-project
        ".beads/"
        ".codegraph/"
        ".gc/"
        ".herdr/"
        ".specify/"
        ".fence.json"
      ];
      settings = {
        core.editor = "nvim";
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
        # `git difftool -t hunk` opens the TUI diff viewer built for
        # reviewing agent-authored changesets. Trust prompt disabled so it
        # doesn't ask on every invocation.
        difftool.hunk.cmd = ''hunk diff "$LOCAL" "$REMOTE"'';
        difftool.prompt = false;
      };
    };
  };
}
