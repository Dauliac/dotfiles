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
        # Keep top-sites visible: the pinned shortcuts we set in
        # settings.nix (browser.newtabpage.pinned) render through the
        # topsites feed, so the feed itself must be on.
        "browser.newtabpage.activity-stream.feeds.topsites" = {
          Value = true;
          Status = "locked";
        };

        # Password manager: never offer to save, never actually store.
        # OfferToSaveLogins above kills the prompt; this locks the
        # about:preferences#privacy toggle too so it can't be re-enabled.
        "signon.rememberSignons" = {
          Value = false;
          Status = "locked";
        };
        "signon.autofillForms" = {
          Value = false;
          Status = "locked";
        };
        # Payment methods / credit cards: belt+braces on top of
        # AutofillCreditCardEnabled.
        "extensions.formautofill.creditCards.enabled" = {
          Value = false;
          Status = "locked";
        };
        "extensions.formautofill.creditCards.available" = {
          Value = false;
          Status = "locked";
        };
        # Addresses: belt+braces on top of AutofillAddressEnabled.
        "extensions.formautofill.addresses.enabled" = {
          Value = false;
          Status = "locked";
        };
        "extensions.formautofill.addresses.available" = {
          Value = "off";
          Status = "locked";
        };
      };
    };
  };
}
