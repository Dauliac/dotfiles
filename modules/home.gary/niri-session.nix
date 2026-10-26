{
  # gary niri session desktop extras: TV screensaver via swayidle + mpv,
  # scale-aware cursor sizing. The niri config itself (inputs, outputs,
  # layout, workspaces, window-rules, binds) is declared in
  # modules/home.gary/niri/*.nix via programs.niri.settings; this file
  # only owns the ambient-session pieces.
  #
  # Historical note: this file was named gnome.nix because the host once
  # ran a GNOME session; the content has been niri-only for a while, the
  # file was renamed on 2026-10-26 for honesty.
  flake.modules.homeManager.user-gary =
    {
      pkgs,
      lib,
      config,
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
      home.pointerCursor = {
        size = lib.mkForce config.systemConstants.display.cursorSize;
        name = lib.mkDefault "catppuccin-mocha-dark-cursors";
        package = lib.mkDefault pkgs.catppuccin-cursors.mochaDark;
      };

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
