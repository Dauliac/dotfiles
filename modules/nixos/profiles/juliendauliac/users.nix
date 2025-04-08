{pkgs, config, ...}: {
  users.users.juliendauliac = {
    isNormalUser = true;
    description = "Julien Dauliac";
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