{ lib, ... }:
{
  config.dotfiles.nixos.sharedModules = lib.mkAfter [
    (_: {
      services.blueman.enable = true;
      hardware = {
        bluetooth = {
          enable = true;
          settings = {
            General = {
              Experimental = true;
            };
          };
        };
      };
    })
  ];
}
