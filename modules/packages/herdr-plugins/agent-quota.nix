# herdr-agent-quota — per-pane sidebar gauges for model / context-window
# / prompt-cache / subscription quota, sourced from each agent CLI's own
# StatusLine. Manifest id `herdr-agent-quota` (hyphen-form — note the
# convention difference vs auto-title's dot-form). Homepage:
# https://github.com/levi-qiao/herdr-agent-quota
#
# Runtime detail (from the manifest): every `[[startup]]`, `[[actions]]`,
# `[[events]]`, and `[[panes]]` command references
# `$HERDR_PLUGIN_ROOT/target/release/herdr-agent-quota` — so the binary
# MUST live at that exact sub-path within the plugin dir. Do NOT flatten
# to $out/ like auto-title does; the plugin will fail to launch.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  installManifest,
}:
rustPlatform.buildRustPackage {
  pname = "herdr-agent-quota";
  version = "1.5.4";

  src = fetchFromGitHub {
    owner = "levi-qiao";
    repo = "herdr-agent-quota";
    rev = "bd91c7ae1ddd1428c9756cc1e6421d76f72fda2a";
    hash = "sha256-Y/LMHGn57p5azX0FLS6wWVKVrL8U8yB8whLy1j9VNmQ=";
  };

  # Bump on every `src.rev` change (any Cargo.lock churn invalidates).
  cargoHash = "sha256-tO5bGENexUGy1XGTHbpyti4FDOFppbXYQdXQtP6Q1kU=";

  # Skip upstream test suite. `claude_collector_does_not_wait_for_a_refresh_lock`
  # in tests/configure_round_trip.rs is timing-based and flakes in the Nix
  # sandbox (532/532 core tests pass — only 1/66 in the round-trip suite
  # fails, and only under sandbox scheduling). Not our code; skipping.
  doCheck = false;

  # $out layout: manifest at root + binary at target/release/<name>,
  # because the manifest's runtime commands reference
  # $HERDR_PLUGIN_ROOT/target/release/herdr-agent-quota. See file header.
  postInstall = ''
    ${installManifest "herdr-agent-quota"}
    mkdir -p $out/target/release
    mv $out/bin/herdr-agent-quota $out/target/release/
    rmdir $out/bin
  '';

  meta = with lib; {
    description = "Per-pane agent quota gauges for herdr (Claude / Codex / Grok / OpenCode / Pi / Devin / …)";
    homepage = "https://github.com/levi-qiao/herdr-agent-quota";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
