{
  lib,
  buildGoModule,
  fetchFromGitHub,
  fetchurl,
  stdenv,
  autoPatchelfHook,
  makeWrapper,
  ast-grep,
}:
let
  version = "2.8.3";

  # Source for building MCP
  src = fetchFromGitHub {
    owner = "JordanCoin";
    repo = "codemap";
    rev = "v${version}";
    hash = "sha256-2wuRZrcnY2qGMclTOxqAOZOMGctbv38IiSVBlUfsNBI=";
  };

  # Binary releases
  binarySources = {
    "x86_64-linux" = {
      url = "https://github.com/JordanCoin/codemap/releases/download/v${version}/codemap-linux-amd64.tar.gz";
      hash = "sha256-FsiMoK/3i+6kgmnWJAzLwK4hxsmZosp9bNjMR7szfqU=";
      dir = "codemap-linux-amd64";
    };
    "aarch64-linux" = {
      url = "https://github.com/JordanCoin/codemap/releases/download/v${version}/codemap-linux-arm64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      dir = "codemap-linux-arm64";
    };
    "x86_64-darwin" = {
      url = "https://github.com/JordanCoin/codemap/releases/download/v${version}/codemap-darwin-amd64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      dir = "codemap-darwin-amd64";
    };
    "aarch64-darwin" = {
      url = "https://github.com/JordanCoin/codemap/releases/download/v${version}/codemap-darwin-arm64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      dir = "codemap-darwin-arm64";
    };
  };
  platformInfo = binarySources.${stdenv.hostPlatform.system};
  binarySrc = fetchurl {
    inherit (platformInfo) url hash;
  };

  # Build MCP server from source with tree-sitter support
  mcp = buildGoModule {
    pname = "codemap-mcp";
    inherit version src;

    vendorHash = "sha256-c8sCU3j9A53Qvuz0QcHIPOUyX80CzCUROpzjD6neODU=";

    # go-tree-sitter ships its C runtime under include/ and src/ which
    # `go mod vendor` prunes. proxyVendor keeps the full module zip so the
    # cgo includes resolve.
    proxyVendor = true;

    subPackages = [ "mcp" ];

    nativeBuildInputs = [ makeWrapper ];
    buildInputs = [ ast-grep ];

    postInstall = ''
      mv $out/bin/mcp $out/bin/codemap-mcp
      wrapProgram $out/bin/codemap-mcp \
        --prefix PATH : ${lib.makeBinPath [ ast-grep ]}
    '';

    meta = with lib; {
      description = "MCP server for codemap - gives Claude access to codebase analysis";
      homepage = "https://github.com/JordanCoin/codemap";
      license = licenses.mit;
      maintainers = [ ];
      mainProgram = "codemap-mcp";
    };
  };
in
stdenv.mkDerivation {
  pname = "codemap";
  inherit version;
  src = binarySrc;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  sourceRoot = platformInfo.dir;

  installPhase = ''
    runHook preInstall
    install -Dm755 codemap $out/bin/codemap
    wrapProgram $out/bin/codemap \
      --prefix PATH : ${lib.makeBinPath [ ast-grep ]}
    runHook postInstall
  '';

  passthru = {
    inherit src version mcp;
  };

  meta = with lib; {
    description = "Generate brain maps of codebases for LLMs";
    homepage = "https://github.com/JordanCoin/codemap";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "codemap";
    platforms = builtins.attrNames binarySources;
  };
}
