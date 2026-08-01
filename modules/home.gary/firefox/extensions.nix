{
  flake.modules.homeManager.user-gary = { pkgs, ... }: {
    programs.firefox.profiles.default = {
      extensions.force = true;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        clearurls
        decentraleyes
        i-dont-care-about-cookies
        consent-o-matic
        proton-pass
        proton-vpn
        sponsorblock
        youtube-shorts-block
        return-youtube-dislikes
        buster-captcha-solver
        adaptive-tab-bar-colour
        containerise
      ];
    };
  };
}
