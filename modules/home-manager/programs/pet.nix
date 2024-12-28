_: {
  programs.pet = {
    enable = true;
    snippets = [
      {
        command = "docker system prune -a -f; nix-store -gc; trash-empty";
        description = "Clean docker, nix, and trash";
        tag = ["docker" "nix" "trash" "cli"];
      }
      {
        command = "git rebase -i HEAD~10";
        description = "Rewrite 10 last commits";
        tag = ["git" "history" "cli"];
      }
      {
        command = "ls $(nix build 'nixpkgs#typescript' --print-out-paths --no-link)";
        description = "List typescript packages";
        tag = ["nix" "package" "cli"];
      }
      {
        command = "kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/\${USER}/.docker/config.json --type=kubernetes.io/dockerconfigjsom --namespace sellsy-system";
        description = "Create kubernetes secret from docker config";
        tag = ["kubernetes" "secret" "docker"];
      }
      {
        command = "systemctl-tui";
        description = "Systemctl tui";
        tag = ["systemd" "tui"];
      }
      {
        command = "lazygit";
        description = "Git tui";
        tag = ["git" "tui"];
      }
      {
        command = "lazydocker";
        description = "Docker tui";
        tag = ["docker" "tui"];
      }
      {
        command = "k9s";
        description = "Kubernetes tui";
        tag = ["kubernetes" "tui"];
      }
      {
        command = "hyperfine";
        description = "Benchmark";
        tag = ["benchmark" "cli"];
      }
      {
        command = "nix repl '<nixpkgs>'";
        description = "Nix repl";
        tag = ["nix" "repl" "cli"];
      }
      {
        command = "sudo sniffnet";
        description = "Sniff network";
        tag = ["network" "sniff" "gui"];
      }
      {
        command = "tldr";
        description = "Commands examples";
        tag = ["help" "command" "cli"];
      }
      {
        command = "git commit --fixup ";
        description = "Commit with fixup";
        tag = ["git" "commit" "cli"];
      }
      {
        command = "steam-tui";
        description = "Run steam";
        tag = ["steam" "tui" "cli"];
      }
      {
        command = "nmtui";
        description = "Run network manager in terminal";
        tag = ["network" "tui" "cli"];
      }
      {
        command = "pulsemixer";
        description = "Run sound mixer in terminal";
        tag = ["sound" "tui" "cli"];
      }
      {
        command = "nix profile rollback";
        description = "To run when profile has unsupported version 3";
        tag = ["nix" "cli" "profile" "fix"];
      }
      {
        command = "export GAMBLE_TEST_COMMAND='cargo test'";
        description = "Define test kube command for git-gamble";
        tag = ["git" "cli" "gamble" "TDD"];
      }
      {
        command = "git green";
        description = "Valid code commit";
        tag = ["git" "cli" "gamble" "TDD"];
      }
      {
        command = "git refactor";
        description = "Refactor code commit";
        tag = ["git" "cli" "gamble" "TDD"];
      }
      {
        command = "git red";
        description = "Invalid code commit";
        tag = ["git" "cli" "gamble" "TDD"];
      }
      {
        command = "git rede";
        description = "With edit invalid code commit";
        tag = ["git" "cli" "gamble" "TDD"];
      }
    ];
  };
}
