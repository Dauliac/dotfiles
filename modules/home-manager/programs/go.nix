{ lib, ... }:
{
  config.dotfiles.home.sharedModules = lib.mkAfter [
    (_: {
      programs.go = {
        enable = true;
        env.GOBIN = ".local/bin.go";
        # telemetry.mode = "off";
      };
    })
  ];
}
