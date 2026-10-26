{
  # Noctalia Shell plugin: anytype-noctalia (watch Anytype collections,
  # quick-add from the bar, inert Kanban slot for a future change).
  # Upstream: github.com/Dauliac/anytype-noctalia
  #
  # Placement model
  # ---------------
  # Noctalia's PluginService.qml dynamically loads any directory under
  # ~/.config/noctalia/plugins/<id>/ that contains a valid manifest.json.
  # We mount the flake input's `plugin/` subdir there via a symlink so
  # hot-reload in debug mode still picks up upstream edits without a
  # rebuild (anytype-noctalia itself is checked out next door in ghq).
  #
  # Credentials
  # -----------
  # The plugin reads its Bearer token via a three-tier precedence:
  #   1. ANYTYPE_API_KEY env var
  #   2. ~/.config/anytype-noctalia/config.toml (preferred)
  #   3. pluginSettings.apiKey (Noctalia settings JSON, fallback)
  # We render (2) via sops.templates so the key lives encrypted at rest
  # (secrets.yaml) and lands on disk only via sops-nix at activation.
  # To wire it, add this to secrets.yaml and re-encrypt with sops:
  #
  #   anytype_api_key: "<paste-the-token-from-anytype-pairing-flow>"
  #
  # Then rebuild. The token is obtained by opening Anytype desktop and
  # using the plugin's Settings UI once to run the challenge pairing,
  # OR by hitting the local pairing endpoints by hand with any HTTP
  # client.
  flake.modules.homeManager.noctalia =
    {
      config,
      pkgs,
      lib,
      inputs,
      ...
    }:
    let
      pluginSrc = "${inputs.anytype-noctalia}/plugin";
      pluginsRoot = "${config.xdg.configHome}/noctalia/plugins";
      configRoot = "${config.xdg.configHome}/anytype-noctalia";
    in
    {
      # Materialise the plugin directory under Noctalia's plugin root.
      # Symlink (not copy) so a `git pull` on the plugin repo updates
      # the live plugin without touching home-manager state. Noctalia's
      # hot-reload picks it up automatically in debug mode.
      home.file."${pluginsRoot}/anytype-noctalia" = {
        source = pluginSrc;
        recursive = false;
      };

      # Render ~/.config/anytype-noctalia/config.toml from the sops
      # secret. Mode 0600 enforced by sops-nix. The TOML schema is
      # pinned by plugin/ConfigFile.qml's parseToml (flat key=value
      # pairs, string values quoted).
      sops.templates."anytype-noctalia/config.toml" = {
        path = "${configRoot}/config.toml";
        mode = "0600";
        content = ''
          mode = "localhost"
          base_url = "http://127.0.0.1:31009"
          api_key = "${config.sops.placeholder.anytype_api_key}"
        '';
      };

      # Declare the secret. The sopsFile defaults to secrets.nix's
      # defaultSopsFile (secrets.yaml). Point the materialised secret
      # file somewhere the user owns so sops-nix can `chown` cleanly;
      # the template above is what the plugin actually reads.
      sops.secrets.anytype_api_key = {
        path = "${configRoot}/.secrets/api_key";
        mode = "0600";
      };
    };
}
