{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
          "github.com-dauliac" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/id_ed25519.perso";
            identitiesOnly = true;
            extraOptions = {
              IdentityAgent = "none";
            };
          };
          "github.com" = {
            hostname = "github.com";
            user = "git";
            identityFile = "~/.ssh/id_rsa";
            identitiesOnly = true;
          };
          "git.manomano.tech" = {
            hostname = "git.manomano.tech";
            user = "git";
            identityFile = "~/.ssh/id_rsa";
            identitiesOnly = true;
          };
        };
      };
    })
  ];
}
