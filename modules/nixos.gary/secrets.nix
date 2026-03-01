{ lib, ... }:
{
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      sops = {
        secrets.gary_hashed_password = { };
      };
    })
  ];
}
