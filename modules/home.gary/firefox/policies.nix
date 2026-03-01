# Firefox policies configuration
# Privacy-focused, disable telemetry and unwanted features
{ lib, ... }:
{
  config.dotfiles.home.userModules.gary = lib.mkAfter [
    (
      { config, ... }:
      lib.mkIf config.dotfiles.gary.firefox.enable {
        programs.firefox.policies = {
          # Disable auto-updates (managed by Nix)
          ExtensionUpdate = false;
          AppAutoUpdate = false;
          BackgroundAppUpdate = false;

          # Privacy: disable autofill
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;

          # Disable unwanted features
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

          # UI settings
          DisplayMenuBar = "default-off";
          DontCheckDefaultBrowser = true;
          OfferToSaveLogins = false;

          # Disable Mozilla messaging
          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
            Locked = true;
          };
        };
      }
    )
  ];
}
