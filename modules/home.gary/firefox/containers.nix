{
  flake.modules.homeManager.user-gary =
    { config, lib, ... }:
    let
      inherit (lib) mkOption types;

      containerSubmodule = types.submodule (
        { name, ... }:
        {
          options = {
            name = mkOption {
              type = types.str;
              default = name;
              description = "Container display name.";
            };
            icon = mkOption {
              type = types.enum [
                "briefcase"
                "cart"
                "chill"
                "circle"
                "dollar"
                "fingerprint"
                "food"
                "fruit"
                "gift"
                "pet"
                "tree"
                "vacation"
              ];
              default = "circle";
              description = "Firefox contextual-identity icon name.";
            };
            color = mkOption {
              type = types.enum [
                "blue"
                "green"
                "orange"
                "pink"
                "purple"
                "red"
                "toolbar"
                "turquoise"
                "yellow"
              ];
              default = "blue";
              description = "Firefox contextual-identity color.";
            };
          };
        }
      );

      specs = config.my.firefox.containers;
      indexed = lib.listToAttrs (
        lib.imap1 (i: n: {
          name = n;
          value = specs.${n} // { id = i; };
        }) (lib.attrNames specs)
      );
    in
    {
      options.my.firefox.containers = mkOption {
        type = types.attrsOf containerSubmodule;
        default = { };
        example = lib.literalExpression ''
          {
            Chloyo  = { icon = "pet";       color = "pink"; };
            Dauliac = { icon = "briefcase"; color = "blue"; };
          }
        '';
        description = ''
          Declarative Firefox containers. Rendered into
          programs.firefox.profiles.default.containers with deterministic
          auto-assigned numeric ids in attr-name order.
        '';
      };

      config = lib.mkIf (specs != { }) {
        programs.firefox.profiles.default = {
          containers = indexed;
          containersForce = true;
          settings."privacy.userContext.enabled" = true;
        };
      };
    };
}
