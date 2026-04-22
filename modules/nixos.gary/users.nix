{
  flake.modules.nixos.gary-users =
    { pkgs, ... }:
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
        shell = pkgs.zsh;
      };
    };
}
