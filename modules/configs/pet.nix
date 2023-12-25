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
      tag = [ "nix" "package" ];
    }
    {
      command =
        "kubectl create secret generic regcred --from-file=.dockerconfigjson=/home/${USER}/.docker/config.json --type=kubernetes.io/dockerconfigjsom --namespace sellsy-system";
      tag = [ "kubernetes" "secret" "docker" ];
    }
  ];
}
