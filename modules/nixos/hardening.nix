{
  pkgs,
  lib,
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
    lockKernelModules = false; # breaks virtd, wireguard and iptables
    # force-enable the Page Table Isolation (PTI) Linux kernel feature
    forcePageTableIsolation = true;
    # User namespaces are required for sandboxing. Better than nothing imo.
    allowUserNamespaces = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
      packages = [ pkgs.apparmor-profiles ];
    };
    virtualisation = {
      #  flush the L1 data cache before entering guests
      flushL1DataCache = "always";
    };
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [
        "-a exit,always -F arch=b64 -S execve"
      ];
    };
    sudo = {
      enable = lib.mkDefault true;
      execWheelOnly = true;
      wheelNeedsPassword = true;
      extraConfig = ''
        # rollback results in sudo lectures after each reboot
        Defaults lecture = never
      '';
    };
  };
}
