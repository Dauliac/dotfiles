{ inputs, ... }: {
  flake.modules.nixos.shell = { config, ... }: {
    imports = [ inputs.self.modules.generic.shell ];

    programs.zsh.enable = config.systemConstants.shell.package.pname == "zsh";

    environment.systemPackages = [ config.systemConstants.shell.package ];
  };
}
