_: {
  sops = {
    age.keyFile = "/home/dauliac/.config/sops/age/dotfiles.txt";
    defaultSopsFile = ../../secrets.yaml;
    secrets.openai_key = { };
    secrets.dauliac_hashed_password = { };
  };
}
