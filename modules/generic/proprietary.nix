_: {
  flake.modules.generic.proprietary-flag = { lib, ... }: {
    options.systemConstants.proprietary.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable proprietary software (Chrome, Slack, gaming emulators, etc.).
        User/host aspects flip this to false for dev/minimal builds.
      '';
    };
  };
}
