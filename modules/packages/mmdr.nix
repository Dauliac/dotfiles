{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage {
  pname = "mmdr";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "1jehuang";
    repo = "mermaid-rs-renderer";
    tag = "v0.2.1";
    hash = "sha256-lQCloOhTqqEU8MNrkUmmJFdoOTEE3j5nvZJo21GJlMU=";
  };

  cargoHash = "sha256-IETAA/TTbdFaZYHMx8imV0cdnq+2VSgU1a4AdcSuxGM=";

  meta = with lib; {
    description = "Fast Mermaid diagram renderer in Rust (SVG/PNG)";
    homepage = "https://github.com/1jehuang/mermaid-rs-renderer";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "mmdr";
  };
}
