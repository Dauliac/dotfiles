_: {
  flake.modules.generic.shell =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.systemConstants.shell = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.zsh;
          description = "The login shell package used across NixOS, system-manager, and home-manager.";
        };
        bin = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = lib.getExe config.systemConstants.shell.package;
          defaultText = lib.literalExpression "lib.getExe config.systemConstants.shell.package";
          description = "Absolute path to the shell binary (derived from package).";
        };
      };
    };
}
