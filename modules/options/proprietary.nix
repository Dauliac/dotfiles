{ lib, ... }:
{
  options.dotfiles.proprietary = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable proprietary software (Chrome, Slack, gaming emulators, etc.). Set to false for dev/minimal builds.";
    };
  };
}
