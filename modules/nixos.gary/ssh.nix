let
  dauliacSecretsDir = ../home.dauliac;
in
{
  flake.modules.nixos.gary-ssh =
    { config, ... }:
    {
      sops.secrets.dauliac_ssh_pub_key = {
        sopsFile = dauliacSecretsDir + "/id_ed25519.enc.pub";
        format = "binary";
      };

      system.activationScripts.dauliacAuthorizedKeys = {
        deps = [ "setupSecrets" ];
        text = ''
          mkdir -p /home/dauliac/.ssh
          cat ${config.sops.secrets.dauliac_ssh_pub_key.path} > /home/dauliac/.ssh/authorized_keys
          chown -R dauliac:users /home/dauliac/.ssh
          chmod 700 /home/dauliac/.ssh
          chmod 600 /home/dauliac/.ssh/authorized_keys
        '';
      };

      services.openssh = {
        enable = true;
        allowSFTP = true;
        settings = {
          PasswordAuthentication = true;
          AllowUsers = [ "dauliac" ];
        };
      };
    };
}
