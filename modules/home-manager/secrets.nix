{ config, ... }: {
  sops = {
    age.keyFile = "${config.home.homeDirectory}.config/sops/age/dotfiles.txt";
    defaultSopsFile = ../../secrets.yaml;
    secrets.openai_key = { };
    secrets.email = { };
  };
  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];
}
