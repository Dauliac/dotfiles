{ config, ... }:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/dotfiles.txt";
    defaultSopsFile = ../../secrets.yaml;
    secrets = {
      gitJulienDauliac = {
        sopsFile = ./profiles/juliendauliac/gitconfig.enc.ini;
        path = "/home/juliendauliac/.config/git/juliendauliac.secrets.ini";
        format = "ini";
      };
      gitDauliac = {
        sopsFile = ./profiles/dauliac/gitconfig.enc.ini;
        path = "/home/juliendauliac/.config/git/dauliac.secrets.ini";
        format = "ini";
      };
    };
  };
  systemd.user.services.mbsync.Unit.After = [ "sops-nix.service" ];
}
