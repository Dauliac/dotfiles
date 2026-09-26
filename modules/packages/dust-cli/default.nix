{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs,
  makeWrapper,
  pkg-config,
  python3,
  libsecret,
}:
buildNpmPackage rec {
  pname = "dust-cli";
  version = "0.4.5";

  src = fetchurl {
    url = "https://registry.npmjs.org/@dust-tt/dust-cli/-/dust-cli-${version}.tgz";
    hash = "sha256-/zGExwh3cXZzA70RMEaMMvlqiUzF3b/c15C/s5XVLwo=";
  };

  # Upstream ships the compiled bundle in `dist/` but omits the lock file
  # from the npm tarball. We vendor a lock generated with `npm install
  # --package-lock-only` against the tarball's declared deps.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-JJFQGF6Tqq+9cEU9x92Lvimx3LFxdCDRjk2PiZJF3ng=";

  # No build script; the bundle in dist/ is what npm publishes.
  dontNpmBuild = true;

  # keytar's postinstall runs node-gyp against libsecret headers.
  nativeBuildInputs = [
    makeWrapper
    pkg-config
    python3
  ];
  buildInputs = [ libsecret ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@dust-tt/dust-cli
    cp -r dist package.json node_modules $out/lib/node_modules/@dust-tt/dust-cli/

    makeWrapper ${nodejs}/bin/node $out/bin/dust \
      --add-flags $out/lib/node_modules/@dust-tt/dust-cli/dist/index.js \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libsecret ]}

    runHook postInstall
  '';

  meta = {
    description = "CLI for Dust — interact with Dust agents from the terminal";
    homepage = "https://docs.dust.tt/docs/developer-platform/dust-cli/dust-cli";
    license = lib.licenses.mit;
    mainProgram = "dust";
    platforms = lib.platforms.unix;
  };
}
