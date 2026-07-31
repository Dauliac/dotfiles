{
  flake.modules.homeManager.sine =
    { pkgs, lib, ... }:
    let
      sineVersion = "2.3.3";
      bootloaderVersion = "0.1.4";

      engineZip = pkgs.fetchurl {
        url = "https://github.com/CosmoCreeper/Sine/releases/download/v${sineVersion}/engine.zip";
        hash = "sha256-yYvo4CNOjE1bQdwne9IBo2Wi3MQY3LqC1HSdJ6ZKPWU=";
      };

      profileZip = pkgs.fetchurl {
        url = "https://github.com/sineorg/bootloader/releases/download/v${bootloaderVersion}/profile.zip";
        hash = "sha256-KFs9WJzJefEfAcnHdBC3F2lMzE8yzBywi9bYkJ+5jgA=";
      };

      programZip = pkgs.fetchurl {
        url = "https://github.com/sineorg/bootloader/releases/download/v${bootloaderVersion}/program.zip";
        hash = "sha256-VcwU69FBoy10bP6T/IrZhW6w1VPMNyfT5AhhfnPUrE0=";
      };

      sineInstallScript = pkgs.writeShellScript "sine-install" ''
        set -euo pipefail

        FLATPAK_APP="app.zen_browser.zen"

        # Resolve flatpak Zen browser program directory
        BROWSER_PATH="$(${pkgs.flatpak}/bin/flatpak info --show-location "$FLATPAK_APP" 2>/dev/null)/files/zen"
        if [ ! -d "$BROWSER_PATH" ]; then
          echo "sine-install: Zen browser flatpak not found, skipping"
          exit 0
        fi

        # Resolve default profile from profiles.ini
        ZEN_DIR="$HOME/.var/app/$FLATPAK_APP/.zen"
        PROFILES_INI="$ZEN_DIR/profiles.ini"
        if [ ! -f "$PROFILES_INI" ]; then
          echo "sine-install: No profiles.ini found at $PROFILES_INI, skipping"
          exit 0
        fi

        # Parse the default profile path (Install section's Default= value)
        PROFILE_REL="$(${pkgs.gawk}/bin/awk -F= '/^\[Install/ {in_install=1; next} /^\[/ {in_install=0} in_install && /^Default=/ {print $2; exit}' "$PROFILES_INI")"
        if [ -z "$PROFILE_REL" ]; then
          # Fallback: first profile with Default=1
          PROFILE_REL="$(${pkgs.gawk}/bin/awk -F= '/^\[Profile/ {in_profile=1; path=""} /^\[/ && !/^\[Profile/ {in_profile=0} in_profile && /^Path=/ {path=$2} in_profile && /^Default=1/ {print path; exit}' "$PROFILES_INI")"
        fi

        if [ -z "$PROFILE_REL" ]; then
          echo "sine-install: Could not determine default profile, skipping"
          exit 0
        fi

        CHROME_DIR="$ZEN_DIR/$PROFILE_REL/chrome"
        mkdir -p "$CHROME_DIR"

        echo "sine-install: Installing Sine v${sineVersion} (bootloader v${bootloaderVersion})"
        echo "  Browser: $BROWSER_PATH"
        echo "  Profile: $ZEN_DIR/$PROFILE_REL"

        # Clean old Sine files
        rm -rf "$CHROME_DIR/JS" "$CHROME_DIR/utils"

        # Install bootloader profile files (utils/ with chrome.manifest etc.)
        ${pkgs.unzip}/bin/unzip -oq "${profileZip}" -d "$CHROME_DIR"

        # Install Sine engine (JS/, locales/, engine.json)
        ${pkgs.unzip}/bin/unzip -oq "${engineZip}" -d "$CHROME_DIR"

        # Install bootloader program files (config.js, defaults/pref/)
        ${pkgs.unzip}/bin/unzip -oq "${programZip}" -d "$BROWSER_PATH"

        echo "sine-install: Done. Restart Zen browser to activate Sine."
      '';
    in
    {
      systemd.user.services.sine-install = {
        Unit = {
          Description = "Install Sine mod manager into Zen browser (flatpak)";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${sineInstallScript}";
          RemainAfterExit = true;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
