# Per-system pkgs configuration with overlays
{
  config,
  inputs,
  ...
}:
{
  config.perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config = config.dotfiles.nixpkgsConfig;
      inherit (config.dotfiles) overlays;
    };
  };
}
