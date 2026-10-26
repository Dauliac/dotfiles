{
  flake.modules.nixos.users = { config, ... }: {
    users.users.dauliac = {
      isNormalUser = true;
      description = "Main user";
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "video"
        "docker"
        "dialout"
        # /dev/input/event* read access for noctalia's bongocat plugin
        # (modules/home-manager/desktop/noctalia/bar.nix  -  evtest-based
        # typing reactivity goes silent without this group).
        "input"
      ];
      shell = config.systemConstants.shell.package;
      hashedPasswordFile = config.sops.secrets.dauliac_hashed_password.path;
    };
  };
}
