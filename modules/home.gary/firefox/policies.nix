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
    };
  };
}
