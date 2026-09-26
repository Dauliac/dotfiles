{
  # NixOS bridge for the shared `system.autoUpgrade.backend` switch.
  #
  # nixpkgs already declares `system.autoUpgrade.*` (see
  # nixos/modules/tasks/auto-upgrade.nix). We *don't* redeclare it here —
  # that would collide with nixpkgs and merge fragilely across releases.
  # We only add one extra option — `system.autoUpgrade.backend` — and
  # then force-disable nixpkgs's `nixos-upgrade.service` and its timer
  # when the operator selects `backend = "ansnix"`. In that mode the
  # NixOS host runs the ansnix Debian-style playbook instead — useful
  # only on hybrid hosts (unlikely in this fleet, but keeps the API
  # symmetric with system-manager).
  #
  # Default `backend = "native"` leaves nixpkgs's implementation intact,
  # so importing this module is a no-op unless you flip the switch.
  flake.modules.nixos.auto-upgrade =
    { config, lib, ... }:
    let
      cfg = config.system.autoUpgrade;
    in
    {
      options.system.autoUpgrade.backend = lib.mkOption {
        type = lib.types.enum [ "ansnix" "native" ];
        default = "native";
        description = ''
          Which implementation applies the upgrades on this host.

          - `native` (default on NixOS): nixpkgs's `nixos-upgrade.service`
            + timer, driven by `system.autoUpgrade.*` as usual.
          - `ansnix`: force-disable the nixpkgs upgrade unit and rely on
            an ansnix-driven playbook (imported separately, e.g. via
            `inputs.ansnix.nixosModules.default`). Only meaningful on a
            NixOS host that also composes the ansnix role — otherwise
            you'll just have no upgrade path.
        '';
      };

      config = lib.mkIf (cfg.enable && cfg.backend == "ansnix") {
        # nixpkgs's module wires WantedBy=timers.target on the timer and
        # ExecStart on the service. mkForce both off so only the ansnix
        # playbook runs, no matter what other option combinations imply.
        systemd.services.nixos-upgrade.enable = lib.mkForce false;
        systemd.timers.nixos-upgrade.enable = lib.mkForce false;
      };
    };
}
