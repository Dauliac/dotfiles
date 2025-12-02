{ config, ... }:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/dotfiles.txt";
    defaultSopsFile = ../../secrets.yaml;
  };
  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];
}
