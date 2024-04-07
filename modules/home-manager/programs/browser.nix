{pkgs, ...}: {
  enabled = true;
  package = pkgs.brave;
  dictionaries = [pkgs.hunspell_en_US pkgs.hunspell_fr_FR];
  extensions = [
    {
      id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
    } # ublock origin
  ];
}
