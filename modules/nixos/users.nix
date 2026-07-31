{
  flake.modules.nixos.users =
    { config, ... }:
    {
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
        ];
        shell = config.systemConstants.shell.package;
        hashedPasswordFile = config.sops.secrets.dauliac_hashed_password.path;
      };
    };
}
