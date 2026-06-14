local M = {}

--- Register all :Goopy* user commands.
---@param goopy table the goopy public API module
function M.register(goopy)
	vim.api.nvim_create_user_command("GoopyInstall", function()
		goopy.install()
	end, { desc = "Install missing plugins" })

	vim.api.nvim_create_user_command("GoopyUpdate", function(opts)
		if opts.args and opts.args ~= "" then
			goopy.update(opts.args)
		else
			goopy.update()
		end
	end, { desc = "Update plugins", nargs = "?" })

	vim.api.nvim_create_user_command("GoopySync", function()
		goopy.sync()
	end, { desc = "Sync plugins (install/update/clean)" })

	vim.api.nvim_create_user_command("GoopyClean", function()
		goopy.clean()
	end, { desc = "Remove unused plugins" })

	vim.api.nvim_create_user_command("GoopyReload", function(opts)
		if opts.args and opts.args ~= "" then
			goopy.reload(opts.args)
		else
			vim.notify("GoopyReload requires a plugin name", vim.log.levels.WARN)
		end
	end, {
		desc = "Reload a plugin",
		nargs = 1,
		complete = function()
			return goopy.list_names()
		end,
	})

	vim.api.nvim_create_user_command("GoopyStatus", function()
		goopy.status()
	end, { desc = "Show plugin status" })

	vim.api.nvim_create_user_command("GoopyLog", function()
		goopy.log()
	end, { desc = "Show goopy log" })

	vim.api.nvim_create_user_command("GoopyProfile", function()
		goopy.profile()
	end, { desc = "Show plugin load time profile" })
end

return M
