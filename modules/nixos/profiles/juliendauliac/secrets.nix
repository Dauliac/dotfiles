{...}: {
    # TODO: add openvpn client config here
    sops.age.keyFile = "/home/juliendauliac/.config/sops/age/dotfiles.txt";
    # TODO: move it into home-manager
    sops.secrets = {
        ovpn_client_ca = {
          sopsFile = ./openvpn/ca.enc.crt;
          path = "/etc/openvpn/client/ca.crt";
          owner = "juliendauliac";
          format = "binary";
        };
        ovpn_client_cert = {
          sopsFile = ./openvpn/client.enc.crt;
          path = "/etc/openvpn/client/client09202.crt";
          owner = "juliendauliac";
          format = "binary";
        };
        ovpn_client_key = {
          sopsFile = ./openvpn/client.enc.key;
          path = "/etc/openvpn/client/client09202.key";
          owner = "juliendauliac";
          format = "binary";
        };
        ovpn_client_config = {
          sopsFile = ./openvpn/client.enc.ovpn;
          owner = "juliendauliac";
          path = "/etc/openvpn/client/config.ovpn";
          format = "binary";
        };
    };
}
