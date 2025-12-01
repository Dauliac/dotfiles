_: {
  home-manager = {
    useGlobalPkgs = true;
    users = {
      gary = {
        imports = [
          ../../../home-manager/profiles/gary
        ];
      };
      dauliac = {
        imports = [
          ../../../home-manager/profiles/dauliac
        ];
      };
    };
  };
}
