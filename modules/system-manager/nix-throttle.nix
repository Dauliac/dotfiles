{ inputs, ... }:
{
  flake.modules.systemManager.nix-throttle =
    { config, lib, ... }:
    let
      cfg = config.systemConstants.nix.throttle;
    in
    {
      imports = [
        inputs.self.modules.generic.cpu
      ];

      options.systemConstants.nix.throttle = {
        enable = lib.mkEnableOption ''
          nix-daemon CPU/IO/memory throttling to keep the desktop responsive
          during builds. Caps parallelism to one derivation at a time, pins the
          daemon to the batch CPU scheduling class, moves I/O to the idle class,
          and applies a memory cap that propagates to every builder via cgroups.
        '';

        cores = lib.mkOption {
          type = lib.types.ints.positive;
          default = config.systemConstants.cpu.count / 2;
          defaultText = lib.literalExpression "systemConstants.cpu.count / 2";
          description = ''
            Threads Nix uses per derivation (nix.settings.cores). Defaults to
            50% of the machine's total logical CPU count, leaving the other
            half for interactive work.
          '';
        };

        memoryHigh = lib.mkOption {
          type = lib.types.str;
          default = "8G";
          description = "Soft memory pressure threshold (systemd MemoryHigh).";
        };

        memoryMax = lib.mkOption {
          type = lib.types.str;
          default = "12G";
          description = "Hard memory cap (systemd MemoryMax) — protects the desktop from build-driven OOM freezes.";
        };
      };

      config = lib.mkIf cfg.enable {
        nix.settings = {
          cores = cfg.cores;
          max-jobs = 1;
        };

        environment.etc."systemd/system/nix-daemon.service.d/50-throttle.conf".text = ''
          [Service]
          CPUSchedulingPolicy=batch
          Nice=19
          CPUWeight=20

          IOSchedulingClass=idle
          IOSchedulingPriority=7
          IOWeight=20

          MemoryHigh=${cfg.memoryHigh}
          MemoryMax=${cfg.memoryMax}

          TasksMax=512
        '';
      };
    };
}
