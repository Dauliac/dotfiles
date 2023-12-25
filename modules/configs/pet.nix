{ ... }: {
  enable = true;
  snippets = [
    {
      command = "docker system prune -a -f; nix-store -gc; trash-empty";
      description = "Clean docker, nix, and trash";
      tag = [ "docker" "nix" "trash" ];
    }
    {
      command = "git rebase -i HEAD~10";
      description = "Rewrite 10 last commits";
      tag = [ "git" "history" ];
    }
    {
      command =
        "ls $(nix build 'nixpkgs#typescript' --print-out-paths --no-link)";
      description = "List typescript packages";
      tag = [ "nix" "package" ];
    }
    {
      command =
        "kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/\${USER}/.docker/config.json --type=kubernetes.io/dockerconfigjsom --namespace sellsy-system";
      description = "Create kubernetes secret from docker config";
      tag = [ "kubernetes" "secret" "docker" ];
    }
    {
      command = "systemctl-tui";
      description = "Systemctl tui";
      tag = [ "systemd" "tui" ];
    }
    {
      command = "lazygit";
      description = "Git tui";
      tag = [ "git" "tui" ];
    }
    {
      command = "lazydocker";
      description = "Docker tui";
      tag = [ "docker" "tui" ];
    }
    {
      command = "k9s";
      description = "Kubernetes tui";
      tag = [ "kubernetes" "tui" ];
    }
    {
      command = "hyperfine";
      description = "Benchmark";
      tag = [ "benchmark" ];
    }
    {
      command = "nix repl '<nixpkgs>'";
      description = "Nix repl";
      tag = [ "nix" "repl" ];
    }
    {
      command = "sniffnet";
      description = "Sniff network";
      tag = [ "network" "sniff" ];
    }
  ];
}
