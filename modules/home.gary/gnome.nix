let
  niriConfigDir = ./.;
in
{
  flake.modules.homeManager.user-gary =
    {
      pkgs,
      lib,
      ...
    }:
    let
      screensaverVideosDir = "~/Videos/screensaver";
      idleTimeoutSeconds = 300;

      videoScreensaverScript = pkgs.writeShellScript "video-screensaver" ''
        ${pkgs.socat}/bin/socat - /tmp/mpv-screensaver <<< 'quit' 2>/dev/null || true

        exec ${pkgs.mpv}/bin/mpv \
          --fullscreen \
          --loop-playlist \
          --shuffle \
          --stop-screensaver=no \
          --no-terminal \
          --no-input-default-bindings \
          --input-ipc-server=/tmp/mpv-screensaver \
          --really-quiet \
          ${screensaverVideosDir}/*
      '';

      stopScreensaverScript = pkgs.writeShellScript "stop-video-screensaver" ''
        ${pkgs.socat}/bin/socat - /tmp/mpv-screensaver <<< 'quit' 2>/dev/null || true
      '';
    in
    {
      xdg.configFile."niri/config.kdl".source = lib.mkForce (niriConfigDir + "/niri-config.kdl");

      home.pointerCursor.size = lib.mkForce 48;

      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = idleTimeoutSeconds;
            command = "${videoScreensaverScript}";
            resumeCommand = "${stopScreensaverScript}";
          }
        ];
        extraArgs = [ "-w" ];
      };

      home.packages = with pkgs; [
        socat
      ];
    };
}
