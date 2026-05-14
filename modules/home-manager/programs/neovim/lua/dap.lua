local dap, dapui = require("dap"), require("dapui")

-- Rust, c, cpp, etc
dap.adapters.lldb = {
	type = "executable",
	command = "lldb-vscode",
	name = "lldb",
}

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
require("dap-go").setup()
require("nvim-dap-virtual-text").setup()
