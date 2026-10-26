{
  flake.modules.homeManager.user-gary = {
    programs.firefox.enable = true;
    programs.firefox.betterfox.enable = true;

    my.firefox.containers = {
      Chloyo = {
        icon = "pet";
        color = "pink";
      };
      Dauliac = {
        icon = "briefcase";
        color = "blue";
      };
    };
  };
}
