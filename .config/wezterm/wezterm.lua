local wezterm = require("wezterm")
local config = wezterm.config_builder()

if wezterm.target_triple:find("windows") then
	config.default_domain = "WSL:Ubuntu-24.04"
end

config.color_scheme = "Gruvbox dark, soft (base16)"
config.window_background_opacity = 0.95

config.font = wezterm.font_with_fallback({
	"UDEV Gothic 35NF",
})
config.font_size = 10.0

config.scrollback_lines = 30000
config.enable_scroll_bar = true

config.keys = {
	{
		key = "K",
		mods = "CTRL|SHIFT",
		action = wezterm.action.Multiple({
			wezterm.action.ClearScrollback("ScrollbackAndViewport"),
			wezterm.action.SendKey({ key = "L", mods = "CTRL" }),
		}),
	},
}

return config
