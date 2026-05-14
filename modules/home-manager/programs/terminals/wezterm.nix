{
  flake.modules.homeManager.wezterm = {
    programs.wezterm = {
      enable = false;
      enableZshIntegration = true;
      extraConfig = ''
        local wezterm = require 'wezterm'
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
        local config = wezterm.config_builder()
        config.front_end = "WebGpu"
        config.enable_wayland = false

        -- font, colors, and opacity managed by stylix
        config.default_cursor_style = "SteadyBar"
        config.hide_tab_bar_if_only_one_tab = true
        config.hide_mouse_cursor_when_typing = false
        config.audible_bell = "Disabled"

        return config
      '';
    };
  };
}
