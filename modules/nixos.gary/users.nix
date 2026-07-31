{
  flake.modules.nixos.gary-users =
    { config, ... }:
    {
      users.groups.gary = { };
      users.users.gary = {
        isNormalUser = true;
        description = "Media user";
        extraGroups = [
          "networkmanager"
          "wheel"
          "audio"
          "video"
          "docker"
          "dialout"
        ];
        shell = config.systemConstants.shell.package;
      };
    };
}
