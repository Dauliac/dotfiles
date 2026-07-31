_: {
  flake.modules.generic.cpu =
    { lib, ... }:
    {
      options.systemConstants.cpu.count = lib.mkOption {
        type = lib.types.ints.positive;
        description = ''
          Total logical CPU count of the machine (threads, not physical cores).
          Set per host. Consumed by throttling traits to compute sensible
          resource budgets (e.g. nix-throttle derives its build core count as
          a fraction of this value).
        '';
      };
    };
}
