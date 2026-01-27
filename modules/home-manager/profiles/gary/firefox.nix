{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    betterfox = {
      enable = true;
    };
    policies = {
      ExtensionUpdate = false;
      AppAutoUpdate = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      BackgroundAppUpdate = false;
      DisableBuiltinPDFViewer = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSetDesktopBackground = true;
      DisplayMenuBar = "default-off";
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      DisableAddonUpdateSecurityWarnings = true;
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        SkipOnboarding = true;
        MoreFromMozilla = false;
        Locked = true;
      };
    };
    profiles.default = {
      isDefault = true;
      extensions.force = true;
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        buster-captcha-solver
        clearurls
        decentraleyes
        ublock-origin
        sponsorblock
        adaptive-tab-bar-colour
        i-dont-care-about-cookies
        consent-o-matic
        proton-pass
        proton-vpn
        youtube-shorts-block
        return-youtube-dislikes
        containerise
      ];
      bookmarks = {
        force = true;
        settings = [
          {
            name = "Bar";
            toolbar = true;
            bookmarks = [
              {
                name = "MyCanal";
                url = "https://www.mycanal.fr/";
              }
              {
                name = "Deezer";
                url = "https://www.deezer.com/";
              }
              {
                name = "Netflix";
                url = "https://www.netflix.com/";
              }
              {
                name = "Spotify";
                url = "https://www.spotify.com/";
              }
              {
                name = "YouTube";
                url = "https://www.youtube.com/";
              }
              {
                name = "Paramount";
                url = "https://www.paramountplus.com/";
              }
              {
                name = "Crunchyroll";
                url = "https://www.crunchyroll.com/";
              }
              {
                name = "Splitte";
                url = "https://www.spliiit.com/";
              }
              {
                name = "Arte";
                url = "https://www.arte.tv/fr/";
              }
              {
                name = "TF1";
                url = "https://www.tf1.fr/";
              }
              {
                name = "Pluto TV";
                url = "https://pluto.tv/";
              }
              {
                name = "Disney+";
                url = "https://www.disneyplus.com";
              }
              {
                name = "M6";
                url = "https://www.m6.fr/";
              }
              {
                name = "Prowlarr";
                url = "http://0.0.0.0:8096";
              }
              {
                name = "Radarr";
                url = "http://0.0.0.0:7878";
              }
            ];
          }
        ];
      };
      settings = {
        "extensions.webextPermissionPrompts" = false;
        "extensions.postDownloadThirdPartyPrompt" = false;
        "layout.css.devPixelsPerPx" = "3";
        "browser.toolbars.bookmarks.visibility" = "always";
      };
    };
  };
}
