{
  # Shared niri aspect for NixOS hosts.
  #
  # Centralises the bongocat (noctalia) runtime prereqs so every niri host
  # inherits them without re-declaring per-host. Bongocat
  # (modules/home-manager/desktop/noctalia/bar.nix) watches
  # /dev/input/by-id/*-event-kbd through `evtest` and animates on PipeWire
  # beats; both signals must be reachable, including inside the
  # `nixos-rebuild build-vm` sandbox used for day-to-day iteration.
  #
  # What this aspect owns:
  #   - programs.niri.enable: lifted out of per-host desktop modules so the
  #     compositor comes from one place. Greeter wiring (greetd+tuigreet
  #     vs greetd+niri-session) still lives per host, since the login
  #     flow differs by host (gary autologins into niri on a TV; spongebob
  #     prompts via tuigreet).
  #   - environment.systemPackages += evtest: the bongocat plugin spawns
  #     evtest children; without it on PATH the paws never move. Keeping
  #     it system-wide (not per-user) means every user that gets niri
  #     also gets the prereq.
  #   - virtualisation.vmVariant QEMU options: see the two blocks below.
  #
  # What this aspect does NOT own:
  #   - users.users.<name>.extraGroups += "input": the user running niri
  #     needs read access to /dev/input/event*, but the username differs
  #     per host (gary, dauliac, ...). Add "input" alongside the other
  #     groups in each host's users.nix. See modules/nixos.gary/users.nix
  #     for the pattern.
  #   - noctalia enablement: that is a home-manager concern wired via
  #     modules/home-manager/desktop/noctalia/.
  flake.modules.nixos.niri = { pkgs, ... }: {
    programs.niri.enable = true;

    environment.systemPackages = [ pkgs.evtest ];

    virtualisation.vmVariant = {
      # QEMU knobs that make bongocat come alive in a build-vm sandbox.
      #
      # 1. USB keyboard with a stable serial.
      #    QEMU's default keyboard (PS/2 or an unserialised usb-kbd) does
      #    not expose vendor/product/serial, so udev's
      #    60-persistent-input.rules never emits
      #    /dev/input/by-id/*-event-kbd. The bar.nix glob
      #    `/dev/input/by-id/*-event-kbd` then matches zero devices and
      #    the plugin silently idles. Adding `serial=bongo-vm-kbd`
      #    forces udev to generate
      #    `usb-QEMU_QEMU_USB_Keyboard_bongo-vm-kbd-event-kbd`, which
      #    the glob picks up.
      #
      # 2. PipeWire audio backend.
      #    rave_mode / tappy_mode (bar.nix:88-90) read a PipeWire
      #    spectrum. Without a QEMU audio device, in-VM PipeWire has
      #    no sink/source and the spectrum is flat. Routing through
      #    `-audiodev pipewire` on the host lets the guest's PipeWire
      #    graph see real audio, so the cat flashes on beats.
      #    Requires the host (laptop running `nixos-rebuild build-vm`)
      #    to have PipeWire running; QEMU in nixpkgs is built with
      #    pipewire backend support.
      virtualisation.qemu.options = [
        "-device"
        "qemu-xhci"
        "-device"
        "usb-kbd,serial=bongo-vm-kbd"

        "-audiodev"
        "pipewire,id=snd0"
        "-device"
        "intel-hda"
        "-device"
        "hda-output,audiodev=snd0"
      ];
    };
  };
}
