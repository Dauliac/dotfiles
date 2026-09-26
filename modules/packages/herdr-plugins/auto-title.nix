# herdr-auto-title — reads the herdr session twice a second and keeps
# every tab's title in step with the work in it. Manifest id
# `herdr.auto-title` (dot-form). Homepage:
# https://github.com/kryptamine/herdr-auto-title
#
# Consumed by `programs.herdr.plugins.auto-title.source = pkgs.herdrPlugins.auto-title`
# in modules/home-manager/programs/herdr.nix. The store output IS the
# plugin dir kevinpita's module hands to `herdr plugin link`: manifest
# at $out/herdr-plugin.toml + binary at $out/herdr-auto-title (matches
# the manifest's `[[startup]] command = ["./herdr-auto-title"]`).
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installManifest,
}:
buildGoModule {
  pname = "herdr-auto-title";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "kryptamine";
    repo = "herdr-auto-title";
    rev = "7fcec810280696b8b38b5bd884be2b340c73e02b";
    hash = "sha256-IrrjMujugCcuRUYubRapVSGp2xSJEC29Lwfcc2FsxT8=";
  };

  # Bump on every `src.rev` change (any go.sum churn upstream invalidates).
  vendorHash = "sha256-QxFp1b7pf7bn3Hh0hyaj8ke5Z61N+WwjhHt3pFiapTs=";

  subPackages = [ "cmd/herdr-auto-title" ];

  ldflags = [
    "-s"
    "-w"
  ];

  # Repurpose $out as the herdr plugin dir (not a normal $out/bin/
  # package): manifest at root + binary at root, matching what
  # `herdr plugin link` expects and the manifest's ./herdr-auto-title
  # startup command.
  postInstall = ''
    ${installManifest "herdr.auto-title"}
    mv $out/bin/herdr-auto-title $out/
    rmdir $out/bin
  '';

  meta = with lib; {
    description = "Automatic contextual tab titles for herdr — reflect branch/agent/activity per pane";
    homepage = "https://github.com/kryptamine/herdr-auto-title";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
