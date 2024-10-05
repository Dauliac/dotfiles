{ pkgs, ... }: {
  services.blueman.enable = true;
  hardware = {
    bluetooth = {
      enable = true;
    };
  };
  hardware.bluetooth.package = pkgs.bluez;
  # NOTE: https://www.reddit.com/r/NixOS/comments/1flrl66/bluetooth_stopped_working_without_new_build/?tl=fr
  # hardware.bluetooth.package = pkgs.bluez.overrideAttrs (finalAttrs: previousAttrs: rec {
  #   version = "5.78";
  #   src = pkgs.fetchurl {
  #     url = "mirror://kernel/linux/bluetooth/bluez-${version}.tar.xz";
  #     sha256 = "sha256-gw/tGRXF03W43g9eb0X83qDcxf9f+z0x227Q8A1zxeM=";
  #   };
  #   patches = [];
  #   buildInputs = previousAttrs.buildInputs ++ [
  #     pkgs.python3Packages.pygments
  #   ];
  # });
}
