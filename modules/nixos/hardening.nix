{
  flake.modules.nixos.hardening =
    {
      lib,
      pkgs,
      ...
    }:
    {
      security = {
        rtkit.enable = true;
        polkit.enable = true;
        pam.services = {
          greetd.enableGnomeKeyring = true;
          greetd.enableKwallet = true;
        };
        protectKernelImage = true;
        lockKernelModules = false;
        forcePageTableIsolation = true;
        allowUserNamespaces = true;
        apparmor = {
          enable = true;
          killUnconfinedConfinables = true;
          packages = [ pkgs.apparmor-profiles ];
        };
        virtualisation.flushL1DataCache = "always";
        auditd.enable = true;
        audit = {
          enable = true;
          rules = [ "-a exit,always -F arch=b64 -S execve" ];
        };
        sudo = {
          enable = lib.mkDefault true;
          execWheelOnly = true;
          wheelNeedsPassword = true;
          extraConfig = ''
            Defaults lecture = never
          '';
        };
      };
    };
}
