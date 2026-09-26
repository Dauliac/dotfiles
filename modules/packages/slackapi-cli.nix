{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
# Slack's OFFICIAL platform CLI — https://github.com/slackapi/slack-cli
# (distinct from rockymadden's `pkgs.slack-cli`, a Bash Web-API wrapper).
#
# Auth is OAuth-session-based: `slack login` prints a magic string, you paste
# it into a slash command inside your Slack workspace, the CLI receives an
# ephemeral session token. No manual `xoxp-…` token to store in sops.
#
# Config + session live at `~/.slack/`. Binary is renamed `slack-cli` → `slack`
# to match upstream naming; no collision because `pkgs.slack` (desktop app)
# isn't installed here (Slack ships via flatpak — see home.juliendauliac).
#
# When bumping the tag, refresh `hash` (source) and `vendorHash`. If unknown,
# set to `lib.fakeHash`, rebuild, and paste the value from nix's error.
buildGoModule {
  pname = "slackapi-cli";
  version = "4.7.0";

  src = fetchFromGitHub {
    owner = "slackapi";
    repo = "slack-cli";
    rev = "v4.7.0";
    hash = "sha256-dSHl3u60WQHj8icfe9ZShh431/IfV25D8l5pZISMOhU=";
  };

  vendorHash = "sha256-RI0j2+9S6kxHALEztV7hnY8NNR5xwUWgG4YHGGXZZiA=";

  ldflags = [
    "-s"
    "-w"
    "-X"
    "github.com/slackapi/slack-cli/internal/version.Version=v4.7.0"
  ];

  # Upstream tests instantiate `~/.slack/` for auth/config; the nix sandbox
  # has no HOME so they fail deterministically. The `slack login` OAuth path
  # is what we exercise post-install anyway — skip tests at build time.
  doCheck = false;

  postInstall = ''
    mv $out/bin/slack-cli $out/bin/slack
  '';

  meta = with lib; {
    description = "Slack's official platform CLI (OAuth-session auth via `slack login`) — for building, deploying, and managing Slack apps";
    homepage = "https://github.com/slackapi/slack-cli";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "slack";
  };
}
