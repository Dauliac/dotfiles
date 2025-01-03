_: {
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      style = "numbers,changes,header";
      map-syntax = [
        # NOTE: use C++ syntax highlighting for header files
        "h:cpp"
        # NOTE: use "gitignore" highlighting for ".ignore" files
        ".ignore:.gitignore"
        ".dockerignore:.gitignore"
      ];
    };
  };
}
