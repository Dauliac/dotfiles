-- All keymaps are now managed by commander.lua
-- This file is kept for backwards compatibility and future custom keymaps

local function set_keymaps()
	-- Set mapleader (also set in commander.lua but keeping here for clarity)
	vim.g.mapleader = ","

	-- Any custom keymaps not managed by commander can go here
	-- Currently empty as all keymaps have been moved to commander.lua
end

return {
	set_keymaps(),
}
