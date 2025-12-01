{
  pkgs,
  ...
}:
{
  services.displayManager.autoLogin = {
    enable = true;
    user = "gary";
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  users = {
    # mutableUsers = false;
    groups = {
      gary = {
      };
    };
    users = {
      gary = {
        isNormalUser = true;
        description = "Media user";
        extraGroups = [
          "networkmanager"
          "wheel"
          "audio"
          "video"
          "docker"
          "dialout"
        ];
        shell = pkgs.zsh;
        # TODO: do it in the fureture
        # hashedPasswordFile = config.sops.secrets.gary_hashed_password.path;
      };
    };
  };
  # TODO: add meta option system to share data between profiles and modules:
  # - home-manager
  # - nixos
  #system.activationScripts."zz-dauliac-authorizedKeys".text = ''
  #  mkdir -p "/etc/ssh/authorized_keys.d";
  #  cp "/home/dauliac/.ssh/id_ed25519.pub" "/etc/ssh/authorized_keys.d/dauliac";
  #  chmod +r "/etc/ssh/authorized_keys.d/dauliac"
  #'';
}
