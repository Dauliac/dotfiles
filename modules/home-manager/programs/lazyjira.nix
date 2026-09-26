{
  flake.modules.homeManager.lazyjira =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      tokenPath = config.sops.secrets.atlassian_api_token.path;

      # keyring-rs 2.x on Linux uses the secret-service crate, which stores
      # items under three attributes. Match them exactly or lazyjira's
      # `Entry::new("lazyjira", "corp").get_password()` returns NoEntry.
      # See: https://github.com/hwchen/keyring-rs/blob/v2.3.3/src/secret_service.rs
      keyringService = "lazyjira";
      profileName = "corp";

      # Seed the keyring from the sops-decrypted token. Idempotent —
      # `secret-tool store` overwrites the existing item. Runs headless-safe:
      # if the session bus / keyring daemon isn't up yet (first activation
      # over ssh, or a rebuild before login), skip without failing the
      # whole switch — user can re-run the wrapper below.
      seedScript = pkgs.writeShellScript "lazyjira-seed-token" ''
        set -u
        if [ ! -r "${tokenPath}" ]; then
          echo "lazyjira: token file ${tokenPath} not readable yet — skipping keyring seed" >&2
          exit 0
        fi
        if [ -z "''${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
          echo "lazyjira: no DBUS_SESSION_BUS_ADDRESS — run \`lazyjira-seed-token\` from a graphical session" >&2
          exit 0
        fi
        ${pkgs.libsecret}/bin/secret-tool store \
          --label="LazyJira API token (${profileName})" \
          service "${keyringService}" \
          username "${profileName}" \
          application "rust-keyring" \
          < "${tokenPath}" \
          || echo "lazyjira: secret-tool store failed — is gnome-keyring-daemon running?" >&2
      '';
    in
    {
      home.packages = [
        pkgs.lazyjira
        # Also expose the seeder as a user-invocable command so a fresh
        # login / newly-unlocked keyring can be seeded without a rebuild.
        (pkgs.writeShellScriptBin "lazyjira-seed-token" ''
          exec ${seedScript} "$@"
        '')
      ];

      # Declarative profile config — url + email + profile-name are
      # corp-sensitive, so they live in `corp.nix` under
      # `sops.templates."corp/lazyjira-config.toml"` and are symlinked
      # into `$XDG_CONFIG_HOME/lazyjira/config.toml` at activation.
      xdg.configFile."lazyjira/config.toml".source =
        config.lib.file.mkOutOfStoreSymlink
          config.sops.templates."corp/lazyjira-config.toml".path;

      # Best-effort seed on each `xi home switch .`. Depends on
      # reloadSystemd so sops-nix has already materialised the token file
      # before we try to read it (matches the codegraphProvisionKick
      # pattern in ai/session/post-activate.nix).
      home.activation.lazyjiraSeedKeyring = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
        $DRY_RUN_CMD ${seedScript} || true
      '';
    };
}
