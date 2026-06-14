local git = require("goopy.git")
local state = require("goopy.state")
local plugin_mod = require("goopy.plugin")
local events = require("goopy.events")
local logger = require("goopy.logger")
local paths = require("goopy.paths")

local M = {}

--- Install a single plugin if it isn't already installed.
---@param plugin table
---@param on_done function(ok: boolean)
local function install_one(plugin, on_done)
	if git.is_repo(plugin.dir) then
		on_done(true)
		return
	end

	state.set_status(plugin.name, state.STATUS.INSTALLING)
	events.emit("install_start", plugin)

	git.clone(plugin.repo, plugin.dir, {
		branch = plugin.branch or plugin.tag,
		depth = require("goopy.config").options.git.depth,
		on_done = function(ok, _, err)
			if ok and plugin.commit then
				ok = git.checkout(plugin.dir, plugin.commit)
			end

			if ok then
				state.set_status(plugin.name, state.STATUS.INSTALLED)
				plugin_mod.run_build(plugin)
				logger.info("installed " .. plugin.name)
			else
				state.set_status(plugin.name, state.STATUS.ERROR, err)
				logger.error("failed to install " .. plugin.name .. ": " .. tostring(err))
			end

			events.emit("install_done", plugin, ok)
			on_done(ok)
		end,
	})
end

--- Install all plugins that are not yet installed.
---@param plugins table<string, table>
---@param on_done function(results: table<string, boolean>)|nil
function M.install(plugins, on_done)
	paths.ensure_dirs()

	local jobs = require("goopy.jobs")
	local tasks = {}
	local names = {}

	for name, plugin in pairs(plugins) do
		if not git.is_repo(plugin.dir) then
			table.insert(names, name)
			table.insert(tasks, function(done)
				install_one(plugin, done)
			end)
		end
	end

	if #tasks == 0 then
		logger.info("nothing to install")
		if on_done then
			on_done({})
		end
		return
	end

	jobs.run_all(tasks, function(results)
		local out = {}
		for i, name in ipairs(names) do
			out[name] = results[i]
		end
		require("goopy.lockfile").write(plugins)
		if on_done then
			on_done(out)
		end
	end)
end

--- Install a single named plugin.
---@param plugins table<string, table>
---@param name string
---@param on_done function(ok: boolean)|nil
function M.install_one(plugins, name, on_done)
	paths.ensure_dirs()
	local plugin = plugins[name]
	if not plugin then
		logger.error("goopy: unknown plugin '" .. name .. "'")
		if on_done then
			on_done(false)
		end
		return
	end

	install_one(plugin, function(ok)
		require("goopy.lockfile").write(plugins)
		if on_done then
			on_done(ok)
		end
	end)
end

return M
