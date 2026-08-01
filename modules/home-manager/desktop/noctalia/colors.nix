{
  flake.modules.homeManager.noctalia = { lib, ... }: {
    programs.noctalia-shell.colors = lib.mapAttrs (_: lib.mkDefault) {
      mPrimary = "#cba6f7";
      mOnPrimary = "#1e1e2e";
      mPrimaryContainer = "#45475a";
      mOnPrimaryContainer = "#cdd6f4";

      mSecondary = "#89b4fa";
      mOnSecondary = "#1e1e2e";
      mSecondaryContainer = "#313244";
      mOnSecondaryContainer = "#cdd6f4";

      mTertiary = "#f5c2e7";
      mOnTertiary = "#1e1e2e";
      mTertiaryContainer = "#45475a";
      mOnTertiaryContainer = "#cdd6f4";

      mError = "#f38ba8";
      mOnError = "#1e1e2e";
      mErrorContainer = "#45475a";
      mOnErrorContainer = "#f38ba8";

      mSurface = "#1e1e2e";
      mOnSurface = "#cdd6f4";
      mOnSurfaceVariant = "#a6adc8";
      mSurfaceContainerLowest = "#11111b";
      mSurfaceContainerLow = "#181825";
      mSurfaceContainer = "#1e1e2e";
      mSurfaceContainerHigh = "#313244";
      mSurfaceContainerHighest = "#45475a";
      mSurfaceBright = "#585b70";
      mSurfaceDim = "#11111b";

      mInverseSurface = "#cdd6f4";
      mInverseOnSurface = "#1e1e2e";
      mInversePrimary = "#7c3aed";

      mOutline = "#6c7086";
      mOutlineVariant = "#45475a";

      mShadow = "#00000066";
      mScrim = "#000000";

      mPrimaryHover = "#b4befe";
      mSecondaryHover = "#74c7ec";
      mTertiaryHover = "#f5c2e7";
      mErrorHover = "#eba0ac";
      mSurfaceHover = "#313244";
    };
  };
}
