{
  # Fully declarative config: any tweak the user makes in the settings
  # window would land in $XDG_STATE_HOME/noctalia/settings.toml (see
  # ConfigService::ConfigService in src/config/config_service.cpp), and
  # would layer on top of ~/.config/noctalia/config.toml at load time.
  #
  # Home Manager symlinks are read-only /nix/store paths, so pinning the
  # state file to an empty store file makes noctalia's writeOverridesToFile
  # calls fail — no runtime tweak ever persists, and the next reload sees
  # only the Nix-declared config.toml.
  flake.modules.homeManager.noctalia =
    { pkgs, ... }:
    {
      home.file.".local/state/noctalia/settings.toml".source =
        pkgs.writeText "noctalia-settings-empty.toml" "";
    };
}
