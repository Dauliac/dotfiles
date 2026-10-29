{
  # Replace the real sops-sourced hashedPasswordFile with a plaintext
  # initial password so a cold VM can be logged into without the age key.
  # Also neuter the dauliac authorizedKeys activation script - it reads a
  # sops secret path that does not exist here.
  flake.modules.nixos.gary-vm-users = { lib, ... }: {
    users.users.dauliac = {
      hashedPasswordFile = lib.mkForce null;
      initialPassword = lib.mkForce "test";
    };
    users.users.gary = {
      hashedPasswordFile = lib.mkForce null;
      initialPassword = lib.mkForce "test";
    };

    system.activationScripts.dauliacAuthorizedKeys = lib.mkForce "";
  };
}
