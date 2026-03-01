{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      services.openssh = {
        enable = true;
        allowSFTP = true;
        settings = {
          PasswordAuthentication = true;
          AllowUsers = [
            "dauliac"
          ];
        };
      };
    })
  ];
}
