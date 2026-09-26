{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  libsecret,
  dbus,
  stdenv,
  darwin,
}:
rustPlatform.buildRustPackage {
  pname = "lazyjira";
  # No tagged release; pin to master HEAD known-good at packaging time.
  version = "0-unstable-2025-12-06";

  src = fetchFromGitHub {
    owner = "jonbito";
    repo = "lazyjira";
    rev = "c0d691e18dbebeb0f8626d60d883cf00c4347e37";
    hash = "sha256-Epw3erLZDHluiiSRYw2Q/eOZNJVS2fpFRWJXCmEO5Ts=";
  };

  cargoHash = "sha256-r+nH5GYpKTM1xYoihO/1oQ0ny84RFt23pdR+Kwd6m/E=";

  nativeBuildInputs = [ pkg-config ];

  # reqwest 0.12 default-tls -> openssl; keyring 2.0 -> libsecret via
  # secret-service (needs dbus at link time).
  buildInputs =
    [
      openssl
      libsecret
      dbus
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      darwin.apple_sdk.frameworks.Security
    ];

  # Tests hit the network / real keyring; skip in the sandbox.
  doCheck = false;

  meta = {
    description = "Terminal-based JIRA TUI (Rust) with JQL filtering and keyring-backed credentials";
    homepage = "https://github.com/jonbito/lazyjira";
    license = lib.licenses.mit;
    mainProgram = "lazyjira";
    platforms = lib.platforms.unix;
  };
}
