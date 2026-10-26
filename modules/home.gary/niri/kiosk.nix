{
  # Point the kiosk enforcer at gary's "junk drawer" workspace: when
  # something lands on the firefox workspace that is not firefox, the
  # enforcer moves it here.
  flake.modules.homeManager.user-gary = {
    myNiri.kiosk.fallbackWorkspace = "apps";
  };
}
