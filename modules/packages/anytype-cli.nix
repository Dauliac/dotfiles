{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule {
  pname = "anytype-cli";
  version = "unstable-2024-12-04";

  src = fetchFromGitHub {
    owner = "epheo";
    repo = "anytype-cli";
    rev = "df6c223db994263322cadd1a8e1287b426e80ace";
    hash = "sha256-lw063zOAfQa8EP0kvVZbXPKrN0S0DVaqzGooGTKbfwk=";
  };

  vendorHash = "sha256-q7NhiKSiW28X5/VRu2COEcPpT+3zH0O72Q+zvsBPrLI=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "Command-line interface for Anytype";
    homepage = "https://github.com/epheo/anytype-cli";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "anytype-cli";
  };
}
