{ pkgs, ... }:
{
  home.packages = with pkgs; [
    stremio
    vlc
    prismlauncher
    ryubing
    shadps4
    google-chrome
    # nerd-fonts.iosevka
  ];
}
