local dap, dapui = require("dap"), require("dapui")

require("neodev").setup({
	library = { plugins = { "nvim-dap-ui" }, types = true },
})

-- Rust, c, cpp, etc
dap.adapters.lldb = {
	type = "executable",
	command = "lldb-vscode", -- adjust as needed, must be absolute path
	name = "lldb",
}

-- bash
dap.adapters.bashdb = {
	type = "executable",
	command = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter",
	name = "bashdb",
}

dap.set_log_level("DEBUG") -- Helps when configuring DAP, see logs with :DapShowLog

dapui.setup()

dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "⏩", texthl = "", linehl = "", numhl = "" })

require("dap.ext.vscode").load_launchjs(nil, { lldb = { "rust" } })
require('dap-go').setup()
require("nvim-dap-virtual-text").setup()
