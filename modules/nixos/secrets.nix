{...}: {
  sops = {
    defaultSopsFile = ../../secrets.yaml;
    secrets.openai_key = { };
    secrets.dauliac_hashed_password = { };
  };
}
