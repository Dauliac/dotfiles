{
  # On-screen keyboard for gary.
  #
  # The NIX-side half: install squeekboard system-wide. The USER unit that
  # actually launches it lives in home-manager scope (modules/home.gary/osk.nix),
  # because niri `systemctl --user import-environment WAYLAND_DISPLAY ...`
  # only reaches HM-managed user units  -  a NixOS-level
  # `systemd.user.services.*` unit comes up before niri publishes the wayland
  # socket and never gets WAYLAND_DISPLAY / DBUS_SESSION_BUS_ADDRESS, so
  # squeekboard binds to nothing and the auto-popup is silently inert.
  flake.modules.nixos.gary-osk =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.squeekboard ];
    };
}
