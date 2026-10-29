{
  # VM uses `dev.raylovers.club` as its single domain.  Public DNS has one
  # wildcard A record: `*.dev.raylovers.club -> 127.0.0.1`.  Any client
  # (host browser via qemu port-forward, VM browser via direct loopback,
  # anyone else on the internet via their own loopback) resolves every
  # <svc>.dev.raylovers.club to their local machine.  Safe by construction:
  # no one else can reach the VM through this record.
  flake.modules.nixos.gary-vm-domain = { lib, ... }: {
    systemConstants.gary.domain = {
      public = lib.mkForce "dev.raylovers.club";
      local = lib.mkForce "dev.raylovers.club";
    };
  };
}
