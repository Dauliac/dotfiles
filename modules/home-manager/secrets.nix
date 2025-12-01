{ config, ... }:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/dotfiles.txt";
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      sshKey = {
        sopsFile = ./profiles/dauliac/id_ed25519.enc;
        path = "/home/dauliac/.ssh/id_ed25519";
        format = "binary";
      };
      sshPubKey = {
        sopsFile = ./profiles/dauliac/id_ed25519.enc.pub;
        path = "/home/dauliac/.ssh/id_ed25519.pub";
        format = "binary";
      };
    };
  };
  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];
}
