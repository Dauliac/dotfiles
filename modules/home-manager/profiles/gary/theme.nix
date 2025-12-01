{ pkgs, ... }:
{
  home.packages = with pkgs; [
    stremio
    vlc
    prismlauncher
    ryujinx
    shadps4
    google-chrome
    k9s
    # nerd-fonts.iosevka
  ];
}
