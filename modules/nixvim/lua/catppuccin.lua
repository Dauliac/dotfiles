-- catppuccin colorscheme + transparent_background are configured declaratively
-- in ui.nix (colorschemes.catppuccin.settings). These highlight overrides force
-- extra UI groups to be transparent so the terminal background shows through.
local groups = {
	"Normal",
	"NonText",
	"SignColumn",
	"VertSplit",
	"StatusLine",
	"StatusLineNC",
	"FoldColumn",
	"ColorColumn",
	"CursorLine",
	"CursorColumn",
}
for _, g in ipairs(groups) do
	vim.cmd("highlight " .. g .. " guibg=none ctermbg=none")
end
