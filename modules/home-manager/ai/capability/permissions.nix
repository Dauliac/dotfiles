{
  # Anti-corruption layer (DDD) between the CAPABILITY and WORKSPACE contexts.
  # Skills speak capability language ("I need to shell out to k9s"); the
  # workspace context stores agent beliefs in ~/.claude/settings.json. This
  # module translates the capability-side need into workspace-side
  # settings.json fragments, which the workspace deep-merge activation in
  # ../workspace/settings.nix picks up under settings.d/. Keeping the ACL
  # in-context means capability-side additions never bypass or corrupt the
  # workspace's authoritative settings.
  #
  # Pre-allowlist entries for skills that shell out to external tools we
  # don't ship ourselves (glab, kubectl, k9s, helm, argo, aws, stu, ...).
  #
  # Ownership rule for permission fragments in this repo:
  #   - Tool shipped by nix in modules/home-manager/ai/*.nix
  #       -> that module owns its own fragment (see herdr-run.nix,
  #          herdr-tui.nix, gc-workflow.nix).
  #   - Tool provided by the environment but only invoked by a skill we ship
  #       -> lives here, keyed by the skill that needs it.
  # Removing a skill from skills.nix without removing its entry here is a
  # tolerable minor drift — the extra allow just becomes noise until the
  # user prunes it. Backup at ~/.claude/settings.json.pre-merge helps.
  #
  # Filename order: 50-59 reserved for skill-owned external-tool perms so
  # they land after nix-shipped tool perms (10-29) and before speculative
  # curated allowlists (60+).
  flake.modules.homeManager.ai-capability-permissions = {
    # ci-watch — GitLab pipeline TUI. Skill runs glab CI/MR subcommands
    # and reads current branch.
    home.file.".claude/settings.d/50-skill-ci-watch.json".text = builtins.toJSON {
      permissions.allow = [
        "Bash(glab ci:*)"
        "Bash(glab mr:*)"
        "Bash(git rev-parse:*)"
      ];
    };

    # k8s-watch — scoped k9s TUI. Skill reads current context + probes
    # jobs/resources via kubectl; may launch k9s directly and observe
    # helm/argo state.
    home.file.".claude/settings.d/51-skill-k8s-watch.json".text = builtins.toJSON {
      permissions.allow = [
        "Bash(kubectl:*)"
        "Bash(k9s:*)"
        "Bash(helm:*)"
        "Bash(argo:*)"
      ];
    };

    # s3-watch — scoped stu (S3 TUI). Skill probes credentials + object
    # presence and launches stu with a bucket/prefix scope.
    home.file.".claude/settings.d/52-skill-s3-watch.json".text = builtins.toJSON {
      permissions.allow = [
        "Bash(aws s3:*)"
        "Bash(aws s3api:*)"
        "Bash(aws sts:*)"
        "Bash(stu:*)"
      ];
    };

    # tui-context deliberately has NO fragment here — the only tool it
    # invokes is herdr-tui, and that permission is owned by herdr-tui.nix.
  };
}
