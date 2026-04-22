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
          stremio
          ryubing
          shadps4
        ];
    };
}
