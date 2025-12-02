_: {
  programs.go = {
    enable = true;
    env.GOBIN = ".local/bin.go";
    # telemetry.mode = "off";
  };
}
