{...}: {
    # TODO: add openvpn client config here
    sops.age.keyFile = "/home/juliendauliac/.config/sops/age/dotfiles.txt";
    # TODO: move it into home-manager
    sops.secrets = {
        dauliac_hashed_password = {};
    };
    # sops.secrets = {
    #     ssh_private_key = {
    #         sopsFile = ./id_ed25519.enc;
    #         type = "binary";
    #         owner = "juliendauliac";
    #         path = "/home/juliendauliac/.ssh/id_ed25519"; 
    #     };
    #     ssh_public_key = {
    #         sopsFile = ./id_ed25519.enc.pub;
    #         type = "binary";
    #         owner = "juliendauliac";
    #         path = "/home/juliendauliac/.ssh/id_ed25519.pub"; 
    #     };
    #     age_key  = {
    #         sopsFile = ./age.key;
    #         type = "binary";
    #         owner = "juliendauliac";
    #         path = "/home/juliendauliac/.ssh/id_ed25519.pub"; 
    #     };
    # };
}