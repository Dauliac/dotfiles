{ ... }:
{
  # Register the system-manager-provided zsh as a valid login shell.
  #
  # `users.users.<name>.shell = config.systemConstants.shell.package;`
  # resolves to /run/system-manager/sw/bin/zsh in /etc/passwd (a stable path
  # symlinked by system-manager's activation). Debian's `pam_shells` rejects
  # any user whose passwd shell is not listed in /etc/shells, so
  # `usermod -s <path>` — even a no-op reassignment on rebuild — fails with:
  #
  #   The value for the SHELL variable was not found in the /etc/shells file
  #
  # Adding the stable path once, declaratively, sidesteps this. The path
  # never rotates across rebuilds so a single line is enough.
  #
  # Priority 45 keeps this ahead of apt-packages (100) / pam-line (110) so
  # that if any later role invokes a sudo/su under this shell it still works.
  # Idempotent via lineinfile.
  flake.modules.systemManager.login-shells = { ... }: {
    ansnix.roles.login-shells = {
      priority = 45;
      tasks = [
        {
          name = "login-shells | ensure /run/system-manager/sw/bin/zsh is a valid login shell";
          "ansible.builtin.lineinfile" = {
            path = "/etc/shells";
            line = "/run/system-manager/sw/bin/zsh";
            state = "present";
            create = true;
            mode = "0644";
          };
        }
      ];
    };
  };
}
