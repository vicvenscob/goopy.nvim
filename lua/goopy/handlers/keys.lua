local M = {}

--- Normalize a keys spec entry into { lhs, mode, rhs, opts }.
---@param key string|table
---@return table
local function normalize_key(key)
	if type(key) == "string" then
		return { lhs = key, mode = "n" }
	end
	return {
		lhs = key[1] or key.lhs,
		rhs = key[2] or key.rhs,
		mode = key.mode or "n",
		desc = key.desc,
	}
end

--- Register placeholder keymaps that load the plugin then replay the keypress.
---@param plugin table
---@param loader table the goopy.loader module
function M.register(plugin, loader)
	local keys = plugin.keys
	if
		type(keys) == "string" or (type(keys) == "table" and keys.lhs == nil and keys[1] and type(keys[1]) ~= "table")
	then
		keys = { keys }
	end

	for _, raw in ipairs(keys) do
		local k = normalize_key(raw)
		local modes = type(k.mode) == "table" and k.mode or { k.mode }

		for _, mode in ipairs(modes) do
			vim.keymap.set(mode, k.lhs, function()
				-- remove the placeholder so the real plugin mapping (if any) takes over
				pcall(vim.keymap.del, mode, k.lhs)
				loader.load(plugin.name)

				if k.rhs then
					if type(k.rhs) == "function" then
						k.rhs()
					else
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k.rhs, true, true, true), "m", false)
					end
				else
					-- replay the original keypress now that the plugin's own mapping exists
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k.lhs, true, true, true), "m", false)
				end
			end, { desc = k.desc or ("Load " .. plugin.name) })
		end
	end
end

return M
