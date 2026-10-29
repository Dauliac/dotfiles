{
  # VM-only: bake a throwaway dev SSH key into gary + dauliac so the
  # host-side AI/bot can SSH in without a password.  The private half
  # lives at ~/.cache/vm-gary-dev/id_ed25519 on the host, never in the
  # repo and never in the VM image.
  #
  # Password auth stays OFF (gary-ssh module default), matching real
  # gary's posture.
  #
  # Also add `dauliac` to AllowUsers so the key accepted on dauliac
  # survives the gary-ssh module's `AllowUsers = [ "dauliac" ]` default
  # without upsetting the real-gary flow.
  flake.modules.nixos.gary-vm-ssh =
    { lib, ... }:
    let
      devKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMBrh2qpquSZd3fw2AAB9T5pAqMTWvrhp1EcXuSwoXEL ai-bot@vm-gary-dev";
    in
    {
      users.users.gary.openssh.authorizedKeys.keys = [ devKey ];
      users.users.dauliac.openssh.authorizedKeys.keys = [ devKey ];

      # gary-ssh declares AllowUsers = [ "dauliac" ].  The VM also
      # autologs in gary on tty1, so make both reachable over SSH too.
      services.openssh.settings.AllowUsers = lib.mkOverride 10 [
        "gary"
        "dauliac"
      ];
    };
}
