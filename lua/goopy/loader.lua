local state = require("goopy.state")
local plugin_mod = require("goopy.plugin")
local events = require("goopy.events")
local logger = require("goopy.logger")

local M = {}

--- @type table<string, table> name -> plugin (set by registration)
M.plugins = {}

--- Load a single plugin onto the runtimepath and run its hooks.
--- Idempotent: returns early if already loaded.
---@param name string
function M.load(name)
	if state.is_loaded(name) then
		return
	end

	local plugin = M.plugins[name]
	if not plugin then
		logger.error("goopy: unknown plugin '" .. name .. "'")
		return
	end

	if not plugin.enabled then
		return
	end

	-- load dependencies first
	for _, dep in ipairs(require("goopy.graph").resolve_deps(plugin, M.plugins)) do
		M.load(dep.name)
	end

	if vim.fn.isdirectory(plugin.dir) == 0 then
		logger.warn("plugin '" .. name .. "' is not installed, skipping load")
		return
	end

	plugin_mod.run_init(plugin)

	vim.opt.runtimepath:append(plugin.dir)
	local after_dir = plugin.dir .. "/after"
	if vim.fn.isdirectory(after_dir) == 1 then
		vim.opt.runtimepath:append(after_dir)
	end

	-- source plugin/*.lua and plugin/*.vim files (deferred plugin scripts)
	local plugin_files = vim.fn.glob(plugin.dir .. "/plugin/**/*.{lua,vim}", false, true)
	for _, file in ipairs(plugin_files) do
		local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(file))
		if not ok then
			logger.error("failed sourcing " .. file .. ": " .. tostring(err))
		end
	end

	state.set_loaded(name)
	plugin_mod.run_config(plugin)

	events.emit("plugin_loaded", plugin)
end

--- Reload a plugin: unload from cache and re-load.
---@param name string
function M.reload(name)
	local plugin = M.plugins[name]
	if not plugin then
		logger.error("goopy: unknown plugin '" .. name .. "'")
		return
	end

	-- clear loaded lua modules belonging to this plugin
	local mod_prefix = plugin.module or plugin.name
	for mod_name, _ in pairs(package.loaded) do
		if mod_name == mod_prefix or mod_name:match("^" .. vim.pesc(mod_prefix) .. "%.") then
			package.loaded[mod_name] = nil
		end
	end

	state.plugins[name].loaded = false
	M.load(name)
	events.emit("plugin_reloaded", plugin)
end

--- Register lazy-load triggers (autocmds, commands, keymaps, filetypes) for all plugins.
---@param plugins table<string, table>
function M.setup_triggers(plugins)
	M.plugins = plugins

	for name, plugin in pairs(plugins) do
		if not plugin.enabled then
			goto continue
		end

		if plugin.startup or not plugin.lazy then
			M.load(name)
			goto continue
		end

		if plugin.event then
			require("goopy.handlers.event").register(plugin, M)
		end
		if plugin.cmd then
			require("goopy.handlers.cmd").register(plugin, M)
		end
		if plugin.ft then
			require("goopy.handlers.ft").register(plugin, M)
		end
		if plugin.keys then
			require("goopy.handlers.keys").register(plugin, M)
		end
		if plugin.module then
			require("goopy.handlers.module").register(plugin, M)
		end

		::continue::
	end
end

return M
