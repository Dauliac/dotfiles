{ inputs, ... }: {
  flake.modules.systemManager.nix-throttle =
    {
      config,
      lib,
      ...
    }:
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

        maxJobs = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
          description = ''
            Number of derivations Nix may build in parallel
            (nix.settings.max-jobs). Defaults to 1 for maximum desktop
            responsiveness; total CPU used is at most `maxJobs * cores`, so
            keep that product below `systemConstants.cpu.count` to leave
            headroom for interactive work.
          '';
        };

        cores = lib.mkOption {
          type = lib.types.ints.positive;
          default = config.systemConstants.cpu.count / (2 * cfg.maxJobs);
          defaultText = lib.literalExpression "systemConstants.cpu.count / (2 * maxJobs)";
          description = ''
            Threads Nix uses per derivation (nix.settings.cores). Default
            scales inversely with maxJobs so the total build CPU budget
            stays around 50% of the machine regardless of parallelism
            (e.g. 16 CPUs → 8 cores × 1 job, or 4 cores × 2 jobs, or
            2 cores × 4 jobs).
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
          inherit (cfg) cores;
          max-jobs = cfg.maxJobs;
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
