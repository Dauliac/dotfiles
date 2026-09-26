{ inputs, ... }:
{
  flake.modules.homeManager.sine =
    {
      config,
      pkgs,
      ...
    }:
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

      flatpakApp = "app.zen_browser.zen";
      zenDir = "${config.home.homeDirectory}/.var/app/${flatpakApp}/.zen";
      # Flatpak `active` symlink flips on every app update; files written under
      # it survive only until Zen upgrades. Move to `~/.local/share/flatpak/…`
      # (user-scope flatpak) if this matters.
      programDir = "/var/lib/flatpak/app/${flatpakApp}/current/active/files/zen";
    in
    {
      imports = [ inputs.ansnix.homeManagerModules.default ];

      ansnix.enable = true;

      # Inline ansnix role — declared purely in Nix, no on-disk role dir.
      # Freeform attrs (zenDir, profileArchives, programArchives) become
      # ansible vars scoped to this role via composePlaybook.
      ansnix.roles.zen-userchrome = {
        priority = 200;

        inherit zenDir;
        profileArchives = [
          { src = profileZip; creates = "utils/chrome.manifest"; }
          { src = engineZip; creates = "engine.json"; }
        ];
        programArchives = [
          {
            src = programZip;
            dest = programDir;
            creates = "${programDir}/config.js";
          }
        ];

        tasks = [
          {
            name = "zen-userchrome | stat profiles.ini";
            "ansible.builtin.stat" = {
              path = "{{ zenDir }}/profiles.ini";
            };
            register = "profilesIni";
          }
          {
            name = "zen-userchrome | skip when Zen profile is absent";
            "ansible.builtin.meta" = "end_play";
            when = "not profilesIni.stat.exists";
          }
          {
            name = "zen-userchrome | slurp profiles.ini";
            "ansible.builtin.slurp" = {
              src = "{{ zenDir }}/profiles.ini";
            };
            register = "profilesIniRaw";
          }
          {
            name = "zen-userchrome | resolve default profile path";
            "ansible.builtin.set_fact" = {
              # Jinja regex — `''..''` avoids Nix string escapes for `\[` etc.
              profileRel = ''{{ (profilesIniRaw.content | b64decode) | regex_search('\[Install[^\]]*\][\s\S]*?Default=([^\r\n]+)', '\1') }}'';
            };
          }
          {
            name = "zen-userchrome | fail if no default profile";
            "ansible.builtin.fail" = {
              msg = "Could not resolve default profile in {{ zenDir }}/profiles.ini";
            };
            when = "profileRel is none or (profileRel | length) == 0";
          }
          {
            name = "zen-userchrome | ensure profile chrome/ dir";
            "ansible.builtin.file" = {
              path = "{{ zenDir }}/{{ profileRel }}/chrome";
              state = "directory";
              mode = "0755";
            };
          }
          {
            name = "zen-userchrome | extract profile archives";
            "ansible.builtin.unarchive" = {
              src = "{{ item.src }}";
              dest = "{{ zenDir }}/{{ profileRel }}/chrome";
              remote_src = false;
              creates = "{{ zenDir }}/{{ profileRel }}/chrome/{{ item.creates }}";
            };
            loop = "{{ profileArchives }}";
            loop_control = {
              label = "{{ item.src | basename }}";
            };
          }
          {
            name = "zen-userchrome | extract program archives";
            "ansible.builtin.unarchive" = {
              src = "{{ item.src }}";
              dest = "{{ item.dest }}";
              remote_src = false;
              creates = "{{ item.creates }}";
            };
            loop = "{{ programArchives }}";
            loop_control = {
              label = "{{ item.src | basename }}";
            };
          }
        ];
      };
    };
}
