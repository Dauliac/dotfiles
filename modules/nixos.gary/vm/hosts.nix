{
  # Intentionally empty: resolution for *.dev.raylovers.club comes from
  # the public DNS wildcard A record set in Cloudflare (`*.dev.raylovers.club
  # -> 127.0.0.1`).  No /etc/hosts rewrites needed inside the VM: public
  # DNS already returns the loopback.  Kept as a dendritic aspect so a
  # future override (self-signed TLS experimentation, offline mode) has
  # one obvious place to land.
  flake.modules.nixos.gary-vm-hosts = _: { };
}
