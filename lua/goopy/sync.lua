local git = require("goopy.git")
local logger = require("goopy.logger")
local paths = require("goopy.paths")

local M = {}

--- Find directories under start/ and opt/ that don't correspond to a configured plugin.
---@param plugins table<string, table>
---@return string[] full paths of unused plugin directories
local function find_unused(plugins)
	local configured_dirs = {}
	for _, plugin in pairs(plugins) do
		configured_dirs[plugin.dir] = true
	end

	local unused = {}
	for _, base in ipairs({ paths.start, paths.opt }) do
		if vim.fn.isdirectory(base) == 1 then
			for _, entry in ipairs(vim.fn.readdir(base)) do
				local full = base .. "/" .. entry
				if vim.fn.isdirectory(full) == 1 and not configured_dirs[full] then
					table.insert(unused, full)
				end
			end
		end
	end

	return unused
end

--- Remove unused plugin directories from disk.
---@param plugins table<string, table>
---@return string[] removed directory names
function M.clean(plugins)
	local unused = find_unused(plugins)
	local removed = {}

	for _, dir in ipairs(unused) do
		local ok = vim.fn.delete(dir, "rf") == 0
		if ok then
			table.insert(removed, vim.fn.fnamemodify(dir, ":t"))
			logger.info("removed unused plugin: " .. vim.fn.fnamemodify(dir, ":t"))
		else
			logger.error("failed to remove " .. dir)
		end
	end

	return removed
end

--- Sync: install missing, update existing, and clean unused plugins to match config.
---@param plugins table<string, table>
---@param on_done function(summary: table)|nil
function M.sync(plugins, on_done)
	local installer = require("goopy.installer")
	local updater = require("goopy.updater")

	installer.install(plugins, function(install_results)
		updater.update(plugins, function(update_results)
			local removed = M.clean(plugins)

			if on_done then
				on_done({
					installed = install_results,
					updated = update_results,
					removed = removed,
				})
			end
		end)
	end)
end

return M
