_: {
  flake.modules.generic.ssh-keys =
    { lib, ... }:
    {
      options.systemConstants.ssh.keys = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { config, ... }:
            {
              options = {
                filename = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Basename of the private key inside ~/.ssh (no directory,
                    no leading tilde). Example: "id_ed25519.perso".
                  '';
                };
                publicFilename = lib.mkOption {
                  type = lib.types.str;
                  default = "${config.filename}.pub";
                  defaultText = lib.literalExpression ''"''${filename}.pub"'';
                  description = "Basename of the matching public key inside ~/.ssh.";
                };
              };
            }
          )
        );
        default = { };
        description = ''
          Named SSH key pairs installed under ~/.ssh on this host.
          Consumers compose absolute or tilde-relative paths as needed
          (git core.sshCommand, sops deploy targets, etc.).
        '';
      };
    };
}
