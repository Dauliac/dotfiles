{
  pkgs,
  lib,
  ...
}:
{
  # TODO: rewrite partitions to have imutable system ?
  # fileSystems."/".options = ["noexec"];
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      firefox-devedition = {
        executable = "${pkgs.firefox-devedition}/bin/firefox-devedition";
        profile = "${pkgs.firejail}/etc/firejail/firefox-developer-edition.profile";
        desktop = "${pkgs.firefox-devedition}/share/applications/firefox-devedition.desktop";
      };
    };
  };
  environment.etc."firejail/firejail.config".text = ''
    browser-allow-drm yes
  '';
  # environment.etc."firejail/firefox-developer-edition.local".text = ''
  #   whitelist ~/Music
  #   noblacklist ~/Music
  #   whitelist ''${HOME}/.gnupg
  #   noblacklist ''${HOME}/.gnupg
  #   dbus-user.talk org.freedesktop.Notifications
  #   dbus-user.talk org.freedesktop.ScreenSaver
  #   dbus-user.talk org.freedesktop.portal.Desktop
  #   dbus-user.talk org.freedesktop.portal.Fcitx
  #   ignore noroot
  #   ignore nou2f
  # '';

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

  # security tweaks borrowed from @hlissner & @fufexan & @NotAShelf
  boot.kernel.sysctl = {
    # The Magic SysRq key is a key combo that allows users connected to the
    # system console of a Linux kernel to perform some low-level commands.
    # Disable it, since we don't need it, and is a potential security concern.
    "kernel.sysrq" = 0;
    ## TCP hardening
    # Prevent bogus ICMP errors from filling up logs.
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # Reverse path filtering causes the kernel to do source validation of
    # packets received from all interfaces. This can mitigate IP spoofing.
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    # Do not accept IP source route packets (we're not a router)
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    # Don't send ICMP redirects (again, we're on a router)
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    # Refuse ICMP redirects (MITM mitigations)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    # Protects against SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;
    # Incomplete protection again TIME-WAIT assassination
    "net.ipv4.tcp_rfc1337" = 1;

    ## TCP optimization
    # TCP Fast Open is a TCP extension that reduces network latency by packing
    # data in the sender’s initial TCP SYN. Setting 3 = enable TCP Fast Open for
    # both incoming and outgoing connections:
    "net.ipv4.tcp_fastopen" = 3;
    # Bufferbloat mitigations + slight improvement in throughput & latency
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";

    "kernel.kexec_load_disabled" = 1;

    # Restrict ptrace() usage to processes with a pre-defined relationship
    # (e.g., parent/child)
    "kernel.yama.ptrace_scope" = 2;
    # Hide kptrs even for processes with CAP_SYSLOG
    "kernel.kptr_restrict" = 2;
    # Disable bpf() JIT (to eliminate spray attacks)
    "net.core.bpf_jit_enable" = false;
    # Disable ftrace debugging
    "kernel.ftrace_enabled" = false;
  };
  boot.kernelModules = [
    "tcp_bbr"
    "btintel"
  ];

  boot.blacklistedKernelModules = [
    # Obscure network protocols
    "rose"
    "netrom"
    "ax25"
    # Old or rare or insufficiently audited filesystems
    "vivid"
    "udf"
    "sysv"
    "squashfs"
    "qnx6"
    "qnx4"
    "omfs"
    "nilfs2"
    "nfsv4"
    "nfsv3"
    "nfs"
    "minix"
    "ksmbd"
    "jfs"
    "jffs2"
    "hpfs"
    "hfsplus"
    "hfs"
    "gfs2"
    "freevxfs"
    "freevxfs"
    "f2fs"
    "exofs"
    "erofs"
    "efs"
    "cramfs"
    "cramfs"
    "cifs"
    "btintel"
    "bfs"
    "befs"
    "affs"
    "adfs"
    "ath3k"
  ];
}
