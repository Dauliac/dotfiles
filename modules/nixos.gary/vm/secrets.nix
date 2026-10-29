{
  # VM is throwaway: no real sops key, no ciphertext file.  Strip the
  # defaultSopsFile pointer, disable validation, and reduce the declared
  # secret set to the handful of stubs the user+ssh modules reference.
  # Any new sops.secrets.* declaration elsewhere in the tree gets
  # overridden to the empty set here, so modules guarded only by their
  # feature flag (not by a `lib.mkIf` on sops) will not try to decrypt.
  flake.modules.nixos.gary-vm-secrets = { lib, ... }: {
    sops.defaultSopsFile = lib.mkForce "/dev/null";
    sops.validateSopsFiles = false;
    sops.secrets = lib.mkForce {
      dauliac_hashed_password = { };
      gary_hashed_password = { };
      dauliac_ssh_pub_key = { };
    };
  };
}
