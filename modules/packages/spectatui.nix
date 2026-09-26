{
  lib,
  fetchurl,
  stdenv,
  autoPatchelfHook,
}:
let
  version = "1.0.1";

  binarySources = {
    "x86_64-linux" = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-2E3NXUCeGecBC/tEtaXfAlX/1WLZgM4YVvwPHsvTkM8=";
    };
    "aarch64-linux" = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-W87TUYmtRnxNpGtP/nItDDdDqj3XEaHygePJIh5Ijko=";
    };
    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      hash = "sha256-lm0pk0FuoqPMpBJ4PAyMHjx4JG2/mWL+IxVwB7SSHDw=";
    };
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      hash = "sha256-emCLsVB+MgSLuySFBwuKSj4OazzSzpA6YBCIeOBVBZU=";
    };
  };
  platformInfo = binarySources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "spectatui";
  inherit version;
  src = fetchurl {
    url = "https://github.com/tinesoft/spectatui/releases/download/v${version}/spectatui-v${version}-${platformInfo.target}.tar.gz";
    inherit (platformInfo) hash;
  };

  sourceRoot = "spectatui-v${version}-${platformInfo.target}";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 spectatui $out/bin/spectatui
    runHook postInstall
  '';

  meta = with lib; {
    description = "Terminal UI to review and navigate GitHub spec-kit projects";
    homepage = "https://github.com/tinesoft/spectatui";
    license = licenses.mit;
    mainProgram = "spectatui";
    platforms = builtins.attrNames binarySources;
  };
}
