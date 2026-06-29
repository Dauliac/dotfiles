{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "datadog-pup";
  version = "1.2.1";

  src = fetchurl {
    url = "https://github.com/DataDog/pup/releases/download/v${version}/pup_${version}_Linux_x86_64.tar.gz";
    hash = "sha256-ySznfbFr7m5jIGx3nFPROLHH1Zg/TWg0nx48ExGHo+Q=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    install -Dm755 pup $out/bin/pup
  '';

  meta = with lib; {
    description = "Give your AI agent a Pup — a CLI companion with 200+ commands across 33+ Datadog products";
    homepage = "https://github.com/DataDog/pup";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pup";
  };
}
