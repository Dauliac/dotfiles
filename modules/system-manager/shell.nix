{ inputs, ... }:
{
  flake.modules.systemManager.shell =
    { config, ... }:
    {
      imports = [
        inputs.self.modules.generic.shell
        inputs.self.modules.systemManager.shell-stubs
      ];

      programs.zsh.enable = config.systemConstants.shell.package.pname == "zsh";

      environment.systemPackages = [ config.systemConstants.shell.package ];
    };
}
