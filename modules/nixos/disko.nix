_:
let
  mkConfig = disk: {
    type = "disk";
    device = disk;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          start = "1MiB";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "defaults"
            ];
          };
        };
        encryptedSwap = {
          size = "26G";
          content = {
            type = "swap";
            resumeDevice = true;
            randomEncryption = true;
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypted";
            #passwordFile = "/tmp/secret.key";
            settings = {
              allowDiscards = true;
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
  main = mkConfig "/dev/nvme0n1";
  backup = mkConfig "/dev/nvme1n1";
in
{
  imports = [
    {
      disko.devices = {
        disk = {
          inherit main;
        };
      };
    }
  ];
}
