{
  # Long-lived, resource-capped Dolt sql-server that backs the Go bd
  # issue tracker (gastownhall/beads). One shared server per host on
  # 127.0.0.1:32867; every beads client (bd invocations, agents, bv)
  # connects to it via the MySQL wire protocol.
  #
  # See openspec change beads-go-migration-and-dolt-caps:
  #   design.md D1 (shared, not per-repo) and D2 (cgroup + GOMEMLIMIT sizing).
  #
  # Tuning attacks three known dolthub/dolt CPU-burn regressions:
  #   #10849 idle GC on ~1GB heap — mitigated by GOMEMLIMIT=768MiB + GOGC=400
  #   #11526 connection slot leak on churn — mitigated by low max_connections
  #          and short read/write timeouts (see xdg.configFile below)
  #   #10944 auto-GC gating on multi-core — fixed in Dolt 2.0.3, our pin 2.3.2.
  flake.modules.homeManager.dolt-beads =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dataDir = "${config.home.homeDirectory}/.local/share/dolt-beads";
      configDir = "${config.xdg.configHome}/dolt-beads";
    in
    {
      # Ensure the data directory exists before the service tries to bind.
      home.activation.doltBeadsDataDir =
        lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
          $DRY_RUN_CMD mkdir -p ${lib.escapeShellArg dataDir}
          $DRY_RUN_CMD chmod 0700 ${lib.escapeShellArg dataDir}
        '';

      # Managed sql-server config. Every knob traced back to an issue or
      # a first-party doc in design.md D2 / specs/ai-runtime/beads/spec.md.
      xdg.configFile."dolt-beads/config.yaml".text = ''
        # Managed by modules/home-manager/services/dolt-beads.nix — do not edit
        # by hand; changes are overwritten on every home-manager switch.
        log_level: warning

        listener:
          host: 127.0.0.1
          port: 32867
          # Beads' churn workload leaks connection slots under dolt#11526.
          # Low ceilings bound the leak; short read/write timeouts reap dead
          # sockets fast.
          max_connections: 8
          back_log: 4
          max_connections_timeout_millis: 5000
          read_timeout_millis: 30000
          write_timeout_millis: 30000

        data_dir: ${dataDir}

        behavior:
          # Fixed by dolt 2.0.3 (see dolt#10944). Our pin is 2.3.2.
          auto_gc_behavior:
            enable: true
            archive_level: 1

        system_variables:
          # A single-user beads DB is measured in megabytes. The Stats v2
          # collector + its GC loop assume production-scale data and
          # burn CPU for no benefit here. Disable both, keep whatever is
          # already in memory paused so nothing writes to disk on tick.
          dolt_stats_enabled: "OFF"
          dolt_stats_gc_enabled: "OFF"
          dolt_stats_memory_only: "ON"
          dolt_stats_paused: "ON"
          # Beads uses no MySQL events; kill the scheduler.
          event_scheduler: "OFF"
          # Short client idle timeout so abandoned CLI sockets don't sit
          # in Sleep for hours (compounds dolt#11526).
          wait_timeout: "30"
      '';

      systemd.user.services.dolt-beads = {
        Unit = {
          Description = "Dolt sql-server for beads (shared, all repos, capped)";
          Documentation = [
            "https://docs.dolthub.com/sql-reference/server/configuration"
            "file://${config.home.homeDirectory}/ghq/github.com/Dauliac/dotfiles/openspec/changes/beads-go-migration-and-dolt-caps/design.md"
          ];
          # Wait for the graphical session to settle so XDG dirs are ready.
          After = [ "default.target" ];
        };

        Service = {
          Type = "simple";
          # Dolt does not implement sd_notify(READY=1); Type=notify is not
          # available. Type=simple + Restart=on-failure is the upstream
          # documented pattern (docs.dolthub.com Application Server guide).
          ExecStart = "${pkgs.dolt}/bin/dolt sql-server --config ${configDir}/config.yaml";
          WorkingDirectory = dataDir;

          # Go runtime env — attacks dolt#10849 (idle GC on ~1GB heap).
          # GOMEMLIMIT forces earlier GC before we hit the cgroup ceiling;
          # GOGC=400 pushes each GC cycle later so we amortize the cost.
          Environment = [
            "GOGC=400"
            "GOMEMLIMIT=768MiB"
          ];

          Restart = "on-failure";
          RestartSec = "2s";
          # Dolt needs a clean SIGTERM + drain to flush the noms journal.
          # A SIGKILL loses in-flight writes.
          KillSignal = "SIGTERM";
          SendSIGKILL = "no";
          TimeoutStopSec = "30s";
          # If the service fails 5 times in a minute, stop restarting.
          StartLimitIntervalSec = "60s";
          StartLimitBurst = 5;

          # cgroup resource caps — sized so a laptop-class host stays
          # responsive while beads workloads have plenty of headroom.
          # All numeric-with-suffix values MUST be strings to avoid
          # nix's type coercion. See design.md D2.
          Slice = "background.slice";
          CPUQuota = "50%";
          MemoryHigh = "1G"; # soft throttle, no OOM
          MemoryMax = "1500M"; # hard cap backstop
          MemorySwapMax = "0"; # Dolt does not swap gracefully
          IOWeight = 50; # de-prioritize I/O below foreground work
          Nice = 10;
          IOSchedulingClass = "best-effort";
          IOSchedulingPriority = 7;
          TasksMax = 256;

          # Hardening — dolt-beads only ever writes to two dirs.
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          ReadWritePaths = [
            dataDir
            configDir
          ];
          PrivateTmp = true;
          NoNewPrivileges = true;
          # Dolt needs a real /dev for terminal size probing; don't
          # over-restrict here.
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
