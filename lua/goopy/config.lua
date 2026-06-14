local plugin_mod = require("goopy.plugin")

local M = {}

M.defaults = {
	-- root path overrides handled in paths.lua via stdpath
	ui = {
		icons = {
			installed = "●",
			pending = "○",
			error = "✗",
			loaded = "✓",
		},
	},
	git = {
		depth = 1,
	},
	log_level = "info",
}

M.options = vim.deepcopy(M.defaults)

--- Merge user options with defaults.
---@param opts table|nil
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})

	local levels = { debug = 1, info = 2, warn = 3, error = 4 }
	local logger = require("goopy.logger")
	logger.level = levels[M.options.log_level] or levels.info
end

--- Parse a list of raw plugin specs (from add()/use() or a setup table)
--- into normalized plugin objects, expanding nested dependency specs.
---@param raw_specs table
---@return table[] plugins keyed list of normalized plugin objects
function M.parse(raw_specs)
	local plugins = {}

	local function collect(raw)
		local p = plugin_mod.normalize(raw)
		plugins[p.name] = p

		-- dependencies may themselves be full specs, not just strings
		for _, dep in ipairs(p.dependencies) do
			if type(dep) == "table" and (dep.repo or dep[1]) then
				collect(dep)
			end
		end
	end

	for _, raw in ipairs(raw_specs) do
		collect(raw)
	end

	return plugins
end

return M
