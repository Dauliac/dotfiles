{config, ...}: {
  sops = {
    # TODO: use config
    age.keyFile = "/home/dauliac/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets.yaml;
    secrets.openai_key = {};
    secrets.email = {};
  };
  systemd.user.services.mbsync.Unit.After = ["sops-nix.service"];
  home.activation.setupEtc = config.lib.dag.entryAfter ["writeBoundary"] ''
    /run/current-system/sw/bin/systemctl start --user sops-nix
  '';
}
