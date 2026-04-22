{
  # Temporarily disabled: catppuccin NixOS module targets newer nixpkgs
  # (references services.displayManager.generic which isn't in release-25.11).
  flake.modules.nixos.theme = { };
}
