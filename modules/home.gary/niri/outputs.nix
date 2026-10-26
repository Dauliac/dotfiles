{
  # TV output presets. All three common HDMI/DP connector names are
  # covered because the physical port depends on the receiver box.
  # scale=2.0 for TV viewing distance.
  flake.modules.homeManager.user-gary = {
    programs.niri.settings.outputs = {
      "HDMI-A-1".scale = 2.0;
      "HDMI-1".scale = 2.0;
      "DP-1".scale = 2.0;
      # Virtual-1 is the QEMU VM output; without an entry it defaults
      # to scale 1 (fine for the sandbox) but we keep it listed so
      # `niri msg outputs` tells a predictable story.
      "Virtual-1".scale = 1.0;
    };
  };
}
