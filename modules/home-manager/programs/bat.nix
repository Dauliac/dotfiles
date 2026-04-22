{
  flake.modules.homeManager.bat = {
    programs.bat = {
      enable = true;
      config = {
        pager = "less -FR";
        style = "numbers,changes,header";
        map-syntax = [
          "h:cpp"
          ".ignore:.gitignore"
          ".dockerignore:.gitignore"
        ];
      };
    };
  };
}
