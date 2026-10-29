{
  # VM-only boot wiring: no display manager inside the VM, so autologin
  # gary on tty1 so the niri tty autostart (zsh profileExtra in
  # modules/home-manager/desktop/niri/session.nix) fires without manual
  # login. The virtualisation module leaves getty@tty1 declared but
  # inactive (nothing pulls it into multi-user.target by default when a
  # GTK display is wired), so attach it to multi-user.target explicitly.
  flake.modules.nixos.gary-vm-boot = { lib, ... }: {
    services.getty.autologinUser = lib.mkForce "gary";
    # getty@tty1 is a template-instance service. nixos's
    # `systemd.services."getty@tty1".wantedBy` does not reliably create
    # the symlink for template instances, so attach it via the target's
    # Wants list instead.
    systemd.targets.multi-user.wants = [ "getty@tty1.service" ];
    # pam_lastlog2 (new in nixpkgs 26.05) opens a SQLite DB at
    # /var/lib/lastlog2/lastlog2.db from login(1). The nixos module does
    # not pre-create the directory, so the first autologin on getty@tty1
    # fails with "System error" and the login shell exits before niri
    # autostart runs. Pre-create the state dir so pam_lastlog2 succeeds.
    systemd.tmpfiles.rules = [
      "d /var/lib/lastlog2 0755 root root -"
    ];
  };
}
