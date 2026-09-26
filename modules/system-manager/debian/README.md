# `system-manager.debian` — declarative Debian bootstrap

A dendritic system-manager module. Any host that imports
`inputs.self.modules.systemManager.debian` gets a `debian-bootstrap.service`
systemd oneshot that runs [`bootstrap.yml`](./bootstrap.yml) via `ansible-core`
(from `/nix/store`, no apt-install) on first boot after activation.

## Scope

Only what nix + system-manager can't do on non-NixOS:

- apt package installs (nix can't touch dpkg)
- PAM edits to `/etc/pam.d/common-*` (dpkg triggers own these files)
- default systemd target
- DankLinux OBS apt repo (paired with the niri install for cohesion)

Everything else (flatpak apps, xdg portals, keyboard layout, niri KDL, palette,
tty1 autostart hook, systemd unit overrides) stays in nix.

## Wiring into a host

```nix
# modules/system-manager.<HOST>/default.nix
{ inputs, ... }: {
  flake.modules.systemManager."host-<host>" =
    { ... }: {
      imports = [ inputs.self.modules.systemManager.debian ];
      # …host-specific config…
    };
}
```

## Trigger

- **Automatic** — `xi system switch . && sudo reboot` → the oneshot fires
  once after `network-online.target`.
- **Manual re-run** — `sudo rm /var/lib/dotfiles/debian-bootstrap.done &&
  sudo systemctl start debian-bootstrap.service`; `journalctl -u
  debian-bootstrap.service -f` to watch.

## Failure semantics

Playbook exits nonzero → marker not created → retries on next boot. Every task
is idempotent so re-runs converge; they never destroy work.
