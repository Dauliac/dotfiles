{ ... }:
{
  # Debian-side declarative bootstrap. Hosts that inherit this module get an
  # `debian-bootstrap.service` systemd oneshot that runs the sibling
  # `bootstrap.yml` playbook via ansible-core (from /nix/store) on first boot
  # after activation.
  #
  # Scope: apt packages, PAM edits, default systemd target, DankLinux repo.
  # Anything nix or system-manager can already own declaratively stays out —
  # see the playbook header for the exact list.
  #
  # Design intent:
  #   - Ansible toolchain comes from `pkgs.ansible` (which wraps
  #     ansible-core) — no apt install of ansible itself on the target.
  #   - The playbook is imported as a nix path → lives at a stable /nix/store
  #     location readable by root at runtime. Must be git-tracked for the
  #     flake to see it.
  #   - `.done` marker prevents re-runs. Delete it if you need to re-converge:
  #       sudo rm /var/lib/dotfiles/debian-bootstrap.done
  #       sudo systemctl start debian-bootstrap.service
  #   - Gated by `network-online.target` — most tasks need apt to reach
  #     mirrors + the DankLinux OBS.
  flake.modules.systemManager.debian =
    { pkgs, ... }:
    let
      # nixpkgs exposes `pkgs.ansible` (wrapping ansible-core + a curated
      # collection bundle). The playbook uses only ansible.builtin.* modules
      # (apt, apt_repository, get_url, file, lineinfile) so the base bundle
      # is enough — no community.general dependency at this scope.
      ansible = pkgs.ansible;

      playbook = ./bootstrap.yml;

      runner = pkgs.writeShellApplication {
        name = "debian-bootstrap";
        runtimeInputs = [
          ansible
          pkgs.coreutils
          pkgs.python3
          # Ansible shells out to these for certain module implementations.
          pkgs.gnutar
          pkgs.gzip
          # gpg is required by ansible.builtin.apt_repository (apt-key was
          # deprecated in Debian 12+ so the module falls back to gpg).
          pkgs.gnupg
        ];
        text = ''
          set -euo pipefail

          # writeShellApplication restricts PATH to runtimeInputs. Debian's
          # apt-mark / dpkg / update-alternatives etc. are needed by the
          # apt / apt_repository modules and live under /usr/bin. Prepend
          # our nix inputs so gpg and coreutils resolve to /nix/store, but
          # keep Debian's /usr/bin reachable as fallback.
          export PATH="$PATH:/usr/sbin:/usr/bin:/sbin:/bin"

          mkdir -p /var/lib/dotfiles

          echo "── running Debian bootstrap via ansible ${ansible.version}"
          ansible-playbook \
            --connection=local \
            --inventory=localhost, \
            "${playbook}"

          touch /var/lib/dotfiles/debian-bootstrap.done
          echo "── bootstrap done. Marker: /var/lib/dotfiles/debian-bootstrap.done"
        '';
      };
    in
    {
      systemd.services.debian-bootstrap = {
        enable = true;
        description = "Debian-side declarative bootstrap (ansible-core in /nix/store)";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${runner}/bin/debian-bootstrap";
        };
        unitConfig = {
          ConditionPathExists = "!/var/lib/dotfiles/debian-bootstrap.done";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
}
