{
  flake.modules.nixos.gary-users = { config, ... }: {
    users.groups.gary = { };
    users.users.gary = {
      isNormalUser = true;
      description = "Media user";
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "video"
        "docker"
        "dialout"
        # Read access to /dev/input/event* for noctalia's bongocat plugin
        # (evtest-based typing reactivity). See
        # modules/home-manager/desktop/noctalia/bar.nix  -  the widget
        # watches /dev/input/by-id/*-event-kbd through evtest and goes
        # silent without this group.
        "input"
      ];
      shell = config.systemConstants.shell.package;
    };
  };
}
