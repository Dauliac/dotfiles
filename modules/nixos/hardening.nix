{
  inputs,
  config,
  pkgs,
  system,
  ...
}: {
  # TODO: rewrite partitions to have imutable system ?
  # fileSystems."/".options = ["noexec"];
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      firefox-devedition = {
        executable = "${pkgs.firefox-devedition}/bin/firefox-devedition";
        profile = "${pkgs.firejail}/etc/firejail/firefox-developer-edition.profile";
        # TODO: use home-manager theme
        extraArgs = ["--env=GTK_THEME=Adwaita:dark"];
        desktop = "${pkgs.firefox-devedition}/share/applications/firefox-devedition.desktop";
      };
    };
  };
}
