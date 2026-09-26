{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
# OpenSpec → beads bridge: reads openspec/changes/<id>/ artifacts and produces a
# nested beads epic (root → sub-epics → leaf tasks) with complexity/tier
# metadata and dependency edges. Used by the `code-workflow` gascity pack's
# `refine` step in place of a hand-written spec-manager decomposer.
#
# Homepage: https://github.com/pstradowski/beads-plan
# Docs on where it fits in the MEOW stack:
#   https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04
#
# When bumping the version tag, also update `hash` (source) and
# `vendorHash` (Go module set). If you don't know the new vendorHash, set it
# to `lib.fakeHash`, rebuild, and paste the value from nix's error message.
buildGoModule {
  pname = "beads-plan";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "pstradowski";
    repo = "beads-plan";
    rev = "v0.1.1";
    hash = "sha256-uUoFC8SqKqPh41H5fvbWRLtYyOqBannNHR804LLOlKk=";
  };

  vendorHash = "sha256-n58Qmiv3gik1qkuXQFbQ+soeOQtUz1dUocEAJepqp/E=";

  # Trim the binary — no debug symbols or DWARF for a CLI wrapper.
  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "Convert OpenSpec task plans into executable beads workflows with complexity assessment, tier-based agent dispatch, and parallelism analysis";
    homepage = "https://github.com/pstradowski/beads-plan";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "beads-plan";
  };
}
