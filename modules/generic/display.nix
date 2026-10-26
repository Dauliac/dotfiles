_: {
  flake.modules.generic.display =
    { lib, config, ... }:
    {
      options.systemConstants.display = {
        scale = lib.mkOption {
          type = lib.types.float;
          default = 1.0;
          description = ''
            Base UI scale factor for this host, 1.0 = standard DPI.

            Set per host: typical laptop = 1.0, 4K/HiDPI = 1.5-2.0,
            TV at living-room viewing distance = 2.5-3.0.

            Downstream knobs (cursor size, firefox devPixelsPerPx, noctalia
            bar thickness, GTK/Qt scale factor env vars) derive from this
            unless overridden explicitly.
          '';
          example = 2.5;
        };

        cursorSize = lib.mkOption {
          type = lib.types.ints.positive;
          default = builtins.floor (16.0 * config.systemConstants.display.scale);
          defaultText = lib.literalExpression "floor (16 * systemConstants.display.scale)";
          description = "Pointer cursor pixel size (used by home.pointerCursor.size).";
        };

        firefoxDevPixelsPerPx = lib.mkOption {
          type = lib.types.float;
          default = config.systemConstants.display.scale;
          defaultText = lib.literalExpression "systemConstants.display.scale";
          description = ''
            Firefox UI zoom (layout.css.devPixelsPerPx). Firefox treats "1.0"
            as auto-detect which usually underestimates on HiDPI, so we feed
            the host's declared scale directly.
          '';
        };

        bar = {
          thickness = lib.mkOption {
            type = lib.types.ints.positive;
            default = builtins.floor (34.0 * config.systemConstants.display.scale);
            defaultText = lib.literalExpression "floor (34 * systemConstants.display.scale)";
            description = "Noctalia bar thickness in pixels.";
          };
          padding = lib.mkOption {
            type = lib.types.ints.positive;
            default = builtins.floor (14.0 * config.systemConstants.display.scale);
            defaultText = lib.literalExpression "floor (14 * systemConstants.display.scale)";
            description = "Noctalia bar inner padding.";
          };
          widgetSpacing = lib.mkOption {
            type = lib.types.ints.positive;
            default = builtins.floor (6.0 * config.systemConstants.display.scale);
            defaultText = lib.literalExpression "floor (6 * systemConstants.display.scale)";
            description = "Noctalia bar spacing between widgets.";
          };
        };

        toolkitEnv = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default =
            let
              s = toString config.systemConstants.display.scale;
            in
            {
              GDK_DPI_SCALE = s;
              QT_SCALE_FACTOR = s;
              # Qt's auto-screen-scale is a parallel codepath that ignores
              # QT_SCALE_FACTOR when set, so disable it so our factor wins.
              QT_AUTO_SCREEN_SCALE_FACTOR = "0";
              XCURSOR_SIZE = toString config.systemConstants.display.cursorSize;
            };
          defaultText = lib.literalExpression "{ GDK_DPI_SCALE = …; QT_SCALE_FACTOR = …; QT_AUTO_SCREEN_SCALE_FACTOR = \"0\"; XCURSOR_SIZE = …; }";
          description = ''
            Session env vars that make GTK/Qt apps follow the declared scale.
            Consume via `home.sessionVariables = config.systemConstants.display.toolkitEnv`.
          '';
        };
      };
    };
}
