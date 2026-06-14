local M = {}

--- Register FileType autocmds that load the plugin for matching filetypes.
---@param plugin table
---@param loader table the goopy.loader module
function M.register(plugin, loader)
	local fts = plugin.ft
	if type(fts) == "string" then
		fts = { fts }
	end

	vim.api.nvim_create_autocmd("FileType", {
		pattern = fts,
		once = true,
		group = vim.api.nvim_create_augroup("Goopy_" .. plugin.name .. "_ft", { clear = true }),
		callback = function()
			loader.load(plugin.name)
		end,
	})
end

return M
