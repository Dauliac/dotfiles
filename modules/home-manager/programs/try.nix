{
  flake.modules.homeManager.try =
    { pkgs, lib, ... }:
    let
      try-cli = pkgs.stdenv.mkDerivation {
        pname = "try-cli";
        version = "0-unstable-2025-11-13";
        src = pkgs.fetchFromGitHub {
          owner = "tobi";
          repo = "try";
          rev = "be566829856ca6bd22963e38a28ffb5efa24c7de";
          hash = "sha256-b+ev9XQDM/nWKFCuF22gUoT0ozxLTd9/fkazW45+WfM=";
        };
        nativeBuildInputs = [ pkgs.makeWrapper ];
        dontBuild = true;
        installPhase = ''
          runHook preInstall
          mkdir -p $out/share/try
          cp -r try.rb lib $out/share/try/
          makeWrapper ${pkgs.ruby}/bin/ruby $out/bin/try \
            --add-flags "$out/share/try/try.rb"
          runHook postInstall
        '';
        meta = {
          description = "Fresh directories for every vibe — quick scratch-dir CLI";
          homepage = "https://github.com/tobi/try";
          license = lib.licenses.mit;
          mainProgram = "try";
          platforms = lib.platforms.unix;
        };
      };
    in
    {
      home.packages = [ try-cli ];

      # `try init` prints a shell function that wraps the binary; eval it into every zsh.
      programs.zsh.initContent = lib.mkAfter ''
        if command -v try >/dev/null 2>&1; then
          eval "$(try init)"
        fi
      '';
    };
}
