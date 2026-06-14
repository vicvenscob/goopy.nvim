local config = require("goopy.config")
local plugin_mod = require("goopy.plugin")
local graph = require("goopy.graph")
local state = require("goopy.state")
local loader = require("goopy.loader")
local logger = require("goopy.logger")
local paths = require("goopy.paths")

local M = {}

--- @type table<string, table> name -> normalized plugin object
M.plugins = {}

--- @type table<string, number> name -> elapsed ms (populated during load)
M.profile_times = {}

--- Initialize goopy with a list of plugin specs and/or options.
---@param opts table { plugins = {...}, ui = {...}, git = {...}, log_level = "info" }
function M.setup(opts)
	opts = opts or {}
	config.setup(opts)
	paths.ensure_dirs()

	local raw_specs = opts.plugins or opts.specs or {}
	M.plugins = config.parse(raw_specs)

	-- detect dependency cycles early
	local _, cycle = graph.sort(M.plugins)
	if cycle then
		logger.error("dependency cycle detected: " .. table.concat(cycle, ", "))
	end

	state.register_all(M.plugins)
	M._wrap_loader_for_profiling()
	loader.setup_triggers(M.plugins)

	require("goopy.commands").register(M)
end

--- Wrap loader.load to record per-plugin load times for :GoopyProfile.
function M._wrap_loader_for_profiling()
	local original_load = loader.load
	loader.load = function(name)
		if state.is_loaded(name) then
			return
		end
		local start = vim.loop.hrtime()
		original_load(name)
		local elapsed = (vim.loop.hrtime() - start) / 1e6
		M.profile_times[name] = elapsed
	end
end

--- Register a new plugin spec at runtime.
---@param spec string|table
function M.add(spec)
	local plugin = plugin_mod.normalize(spec)
	M.plugins[plugin.name] = plugin
	state.register(plugin)
	loader.plugins = M.plugins

	if plugin.startup or not plugin.lazy then
		loader.load(plugin.name)
	else
		loader.setup_triggers({ [plugin.name] = plugin })
	end

	return plugin
end

-- alias
M.use = M.add

--- Unregister a plugin from config (does not remove from disk; use clean()/sync()).
---@param name string
function M.remove(name)
	if not M.plugins[name] then
		logger.warn("goopy: '" .. name .. "' is not registered")
		return
	end
	M.plugins[name] = nil
	state.plugins[name] = nil
	loader.plugins = M.plugins
end

--- Install plugins that are missing on disk.
---@param name string|nil install only this plugin
---@param on_done function|nil
function M.install(name, on_done)
	local installer = require("goopy.installer")
	if name then
		installer.install_one(M.plugins, name, on_done)
	else
		installer.install(M.plugins, on_done)
	end
end

--- Update installed plugins.
---@param name string|nil update only this plugin
---@param on_done function|nil
function M.update(name, on_done)
	local updater = require("goopy.updater")
	if name then
		updater.update_one(M.plugins, name, on_done)
	else
		updater.update(M.plugins, on_done)
	end
end

--- Sync: install/update/remove to match config.
---@param on_done function|nil
function M.sync(on_done)
	require("goopy.sync").sync(M.plugins, on_done)
end

--- Remove plugins on disk that are no longer in config.
---@return string[] removed plugin names
function M.clean()
	return require("goopy.sync").clean(M.plugins)
end

--- Load a plugin immediately (bypassing its lazy triggers).
---@param name string
function M.load(name)
	loader.load(name)
end

--- Reload a plugin (clear its modules and re-run config()).
---@param name string
function M.reload(name)
	loader.reload(name)
end

--- Get the list of all configured plugin objects.
---@return table[]
function M.list()
	local out = {}
	for _, plugin in pairs(M.plugins) do
		table.insert(out, plugin)
	end
	table.sort(out, function(a, b)
		return a.name < b.name
	end)
	return out
end

--- Get just plugin names (used for command completion).
---@return string[]
function M.list_names()
	local names = {}
	for name, _ in pairs(M.plugins) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--- Show plugin status in a floating window.
function M.status()
	require("goopy.ui").status()
end

--- Show the goopy log in a floating window.
function M.log()
	require("goopy.ui").log()
end

--- Show per-plugin load time profile in a floating window.
function M.profile()
	local lines = { "Goopy Load Profile", "" }
	local entries = {}
	for name, ms in pairs(M.profile_times) do
		table.insert(entries, { name = name, ms = ms })
	end
	table.sort(entries, function(a, b)
		return a.ms > b.ms
	end)

	local total = 0
	for _, e in ipairs(entries) do
		total = total + e.ms
		table.insert(lines, string.format("  %6.2fms  %s", e.ms, e.name))
	end
	table.insert(lines, "")
	table.insert(lines, string.format("  total: %.2fms across %d plugins", total, #entries))

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	local width = math.min(60, vim.o.columns - 10)
	local height = math.min(#lines + 2, vim.o.lines - 4)

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " goopy.nvim profile ",
		title_pos = "center",
	})

	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
	vim.keymap.set("n", "<esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })
end

--- Restore all plugins to the commits recorded in the lockfile.
---@param on_done function|nil
function M.restore(on_done)
	require("goopy.lockfile").restore(M.plugins, on_done)
end

return M
