{
  config,
  pkgs,
  ...
}:
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
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.dauliac_hashed_password.path;
  };
}
