{
  flake.modules.homeManager.user-gary = {
    programs.firefox.policies = {
      ExtensionUpdate = false;
      AppAutoUpdate = false;
      BackgroundAppUpdate = false;

      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      DisableBuiltinPDFViewer = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisableForgetButton = true;
      DisableMasterPasswordCreation = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSetDesktopBackground = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisableFormHistory = true;
      DisablePasswordReveal = true;
      DisableAddonUpdateSecurityWarnings = true;

      DisplayMenuBar = "default-off";
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;

      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        SkipOnboarding = true;
        MoreFromMozilla = false;
        Locked = true;
      };

      # New Tab Page cleanup. Firefox 136+ added a weather widget, sponsored
      # tiles, and story recommendations to about:newtab that none of the
      # enterprise policy top-level keys above cover. Lock the underlying
      # activity-stream prefs so the user can't toggle them back by accident
      # and a Firefox update can't flip the default back on.
      Preferences = {
        "browser.newtabpage.activity-stream.showWeather" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.system.showWeather" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.showSponsored" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.feeds.section.topstories" = {
          Value = false;
          Status = "locked";
        };
        "browser.newtabpage.activity-stream.feeds.topsites" = {
          Value = false;
          Status = "locked";
        };
      };
    };
  };
}
