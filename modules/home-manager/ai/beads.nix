{
  # Beads-specific home-manager configuration. Kept in the AI module scope
  # (not programs/git.nix) so it lives with the beads package itself — if the
  # AI stack ever gets pruned, this vanishes with it.
  flake.modules.homeManager.beads = {
    # Silences bd's `git config beads.role` warning. `~/.config/git/config`
    # is a nix-store symlink, so `git config --global beads.role maintainer`
    # can't write to it — declare the value here instead.
    programs.git.settings.beads.role = "maintainer";
  };
}
