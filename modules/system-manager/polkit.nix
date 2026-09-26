{ ... }:
{
  # Backfill /etc/pam.d/polkit-1 on Debian hosts. Some Debian installs ship
  # polkitd without the polkit-1 PAM stanza (or it gets stripped by a
  # partial upgrade); without that file `polkit-agent-helper-1` cannot
  # authenticate the operator and every pkexec-mediated action fails with
  #   polkit-agent-helper-1: pam_authenticate failed: Authentication failure
  # `xi system switch .` is the usual first casualty because xi routes
  # elevation through pkexec (see modules/home-manager/programs/xi.nix).
  #
  # Content mirrors the stanza the polkitd package normally installs on
  # Debian: delegate every phase to the common-* aggregators so pam-line
  # roles composed elsewhere (gnome-keyring, etc.) apply here too.
  flake.modules.systemManager.polkit = { ... }: {
    ansnix.roles.polkit-pam = {
      priority = 55;
      tasks = [
        {
          name = "polkit-pam | ensure /etc/pam.d/polkit-1 exists";
          "ansible.builtin.copy" = {
            dest = "/etc/pam.d/polkit-1";
            content = ''
              #%PAM-1.0
              auth       include        common-auth
              account    include        common-account
              password   include        common-password
              session    include        common-session
            '';
            owner = "root";
            group = "root";
            mode = "0644";
          };
        }

        # Debian's polkitd package has shipped polkit-agent-helper-1 with the
        # setuid bit stripped after some upgrades (observed 2026-09-19 on
        # ML-PF603JJ8: file arrived as 0755 instead of 4755, breaking every
        # pkexec-mediated auth — the agent dialog appeared but Authenticate
        # silently failed because the helper cannot read /etc/shadow without
        # setuid root). Pin the mode with dpkg-statoverride so apt cannot
        # strip it again on the next polkitd upgrade. Decomposed into
        # probe → parse → (remove-if-wrong) → add so each step reports its
        # own change state and is safe under --check.
        {
          name = "polkit-pam | probe dpkg-statoverride for polkit-agent-helper-1";
          "ansible.builtin.command" = {
            cmd = "dpkg-statoverride --list /usr/lib/polkit-1/polkit-agent-helper-1";
          };
          register = "polkit_helper_statoverride";
          changed_when = false;
          failed_when = false;
          check_mode = false;
        }
        {
          name = "polkit-pam | resolve desired vs current override facts";
          "ansible.builtin.set_fact" = {
            polkit_helper_override_current = "{{ polkit_helper_statoverride.stdout | trim }}";
            polkit_helper_override_desired = "root root 4755 /usr/lib/polkit-1/polkit-agent-helper-1";
          };
        }
        {
          name = "polkit-pam | drop incorrect dpkg-statoverride before re-pinning";
          "ansible.builtin.command" = {
            cmd = "dpkg-statoverride --remove /usr/lib/polkit-1/polkit-agent-helper-1";
          };
          when = [
            "polkit_helper_override_current | length > 0"
            "polkit_helper_override_current != polkit_helper_override_desired"
          ];
        }
        {
          name = "polkit-pam | pin polkit-agent-helper-1 to root:root 4755 via dpkg-statoverride";
          "ansible.builtin.command" = {
            cmd = "dpkg-statoverride --add --update root root 4755 /usr/lib/polkit-1/polkit-agent-helper-1";
          };
          when = "polkit_helper_override_current != polkit_helper_override_desired";
        }
      ];
    };
  };
}
