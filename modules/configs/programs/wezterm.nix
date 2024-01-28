{ package, ... }: {
  inherit package;
  enable = true;
  enableZshIntegration = true;
  extraConfig = ''
    local
    wezterm = require 'wezterm';

    wezterm.on('user-var-changed', function(window, pane, name, value)
        local overrides = window:get_config_overrides() or {}
        if name == "ZEN_MODE" then
            local incremental = value:find("+")
            local number_value = tonumber(value)
            if incremental ~= nil then
                while (number_value > 0) do
                    window:perform_action(wezterm.action.IncreaseFontSize, pane)
                    number_value = number_value - 1
                end
                overrides.enable_tab_bar = false
            elseif number_value < 0 then
                window:perform_action(wezterm.action.ResetFontSize, pane)
                overrides.font_size = nil
                overrides.enable_tab_bar = true
            else
                overrides.font_size = number_value
                overrides.enable_tab_bar = false
            end
        end
        window:set_config_overrides(overrides)
    end)

    return {
      color_scheme = "Gruvbox Dark (Gogh)",

      window_background_opacity = 0.89,
      font = wezterm.font(
        "FiraCode Nerd Font Mono",
        {bold=false, weight = "Regular", stretch = "Normal", italic = false}
      ),
      default_cursor_style = "SteadyBar",
      hide_tab_bar_if_only_one_tab = true,
    }
  '';
}
