{
  flake.modules.homeManager.user-gary =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      proprietaryEnabled = config.systemConstants.proprietary.enable;
    in
    {
      home.packages =
        with pkgs;
        [
          k9s
          vlc
          prismlauncher
        ]
        ++ lib.optionals proprietaryEnabled [
          # nixpkgs 26.05 removed `stremio` (qt5 webengine CVE); the linux-shell
          # package is the suggested replacement.
          stremio-linux-shell
          ryubing
          shadps4
        ];
    };
}
