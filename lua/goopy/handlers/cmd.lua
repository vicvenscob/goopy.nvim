local M = {}

--- Register user-command stubs that load the plugin then re-dispatch the command.
---@param plugin table
---@param loader table the goopy.loader module
function M.register(plugin, loader)
	local cmds = plugin.cmd
	if type(cmds) == "string" then
		cmds = { cmds }
	end

	for _, cmd_name in ipairs(cmds) do
		vim.api.nvim_create_user_command(cmd_name, function(opts)
			vim.api.nvim_del_user_command(cmd_name)
			loader.load(plugin.name)

			-- re-dispatch the real command now that the plugin is loaded
			local cmd_str = cmd_name
			if opts.args and opts.args ~= "" then
				cmd_str = cmd_str .. " " .. opts.args
			end
			local ok, err = pcall(vim.cmd, {
				cmd = cmd_name,
				args = opts.fargs,
				bang = opts.bang,
				range = opts.range > 0 and { opts.line1, opts.line2 } or nil,
			})
			if not ok then
				require("goopy.logger").error("failed to dispatch '" .. cmd_str .. "': " .. tostring(err))
			end
		end, {
			nargs = "*",
			range = true,
			bang = true,
			complete = "file",
		})
	end
end

return M
