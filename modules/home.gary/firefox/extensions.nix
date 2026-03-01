# Firefox extensions configuration
# Privacy, ad-blocking, and quality-of-life extensions
{ lib, ... }:
{
  config.dotfiles.home.userModules.gary = lib.mkAfter [
    (
      { config, pkgs, ... }:
      lib.mkIf config.dotfiles.gary.firefox.enable {
        programs.firefox.profiles.default = {
          extensions.force = true;
          extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
            # Privacy & Security
            ublock-origin
            clearurls
            decentraleyes

            # Cookie & Consent management
            i-dont-care-about-cookies
            consent-o-matic

            # Proton services
            proton-pass
            proton-vpn

            # YouTube improvements
            sponsorblock
            youtube-shorts-block
            return-youtube-dislikes

            # Utilities
            buster-captcha-solver
            adaptive-tab-bar-colour
            containerise
          ];
        };
      }
    )
  ];
}
