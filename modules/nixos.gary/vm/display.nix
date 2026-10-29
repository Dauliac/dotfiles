{
  # Real gary drives a living-room TV at viewing distance (scale 3.0 set
  # in modules/nixos.gary/default.nix).  The VM is a laptop-sized dev
  # sandbox, not a TV, so drop to 1.0.  Firefox, cursor, and the
  # noctalia bar then render at normal size.
  flake.modules.nixos.gary-vm-display = { lib, ... }: {
    systemConstants.display.scale = lib.mkForce 1.0;
  };
}
