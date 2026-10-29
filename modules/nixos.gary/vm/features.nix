{
  # Single source of truth for which host features are active inside the
  # VM sandbox.  Keeping every override in one file makes it obvious at a
  # glance which services the browser can hit and which are stubbed.
  #
  # Group 1 - public-exposure stack: not applicable inside a VM.
  #   acme         - no Let's Encrypt (no public DNS, no port 80/443)
  #   cloudflared  - no tunnel (no real sops token in the VM)
  #   reverseProxy - enabled so nginx still serves on gary.local
  #
  # Group 2 - media stack (nixflix): disabled.  The arr services need
  #   /data mount + SOPS api keys that a throwaway VM lacks.
  #
  # Group 3 - home automation stack: disabled.  Each of these has a
  #   hard dependency on either SOPS templates (mqtt_password placeholder)
  #   or physical peripherals (USB zigbee coordinator, Matter radio,
  #   ESP devices) that the VM cannot stub cleanly.
  flake.modules.nixos.gary-vm-features = { lib, ... }: {
    systemConstants.gary.featureFlags = {
      # Group 1 - public exposure
      acme = lib.mkForce false;
      cloudflared = lib.mkForce false;
      reverseProxy = lib.mkForce true;

      # Group 2 - media stack
      # Real `nixflix` meta-wrapper is off (needs sops + /data mount).
      # Instead, `vmArrStack` triggers modules/nixos.gary/vm/arr.nix
      # which instantiates each arr service directly from nixpkgs for
      # browser-level smoke testing.
      nixflix = lib.mkForce false;
      nixflixVpn = lib.mkForce false;
      vmArrStack = lib.mkForce true;

      # Group 3 - home automation
      homeAssistant = lib.mkForce false;
      mosquitto = lib.mkForce false;
      esphome = lib.mkForce false;
      zigbee2mqtt = lib.mkForce false;
      matterServer = lib.mkForce false;
      haArrIntegration = lib.mkForce false;
    };
  };
}
