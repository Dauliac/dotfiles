_: {
  services.openssh = {
    enable = true;
    allowSFTP = true;
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [
        "dauliac"
      ];
    };
  };
}
