local git = require("goopy.git")
local state = require("goopy.state")
local plugin_mod = require("goopy.plugin")
local events = require("goopy.events")
local logger = require("goopy.logger")

local M = {}

--- Update a single plugin, recording the before/after commit for :GoopyLog.
---@param plugin table
---@param on_done function(ok: boolean, log: string[]|nil)
local function update_one(plugin, on_done)
	if not git.is_repo(plugin.dir) then
		on_done(false, nil)
		return
	end

	local before = git.head(plugin.dir)
	state.set_status(plugin.name, state.STATUS.UPDATING)
	events.emit("update_start", plugin)

	git.update(plugin.dir, {
		branch = plugin.branch,
		on_done = function(ok, _, err)
			local log_entries = nil

			if ok then
				local after = git.head(plugin.dir)
				if before ~= after then
					log_entries = git.log(plugin.dir, before, after)
					plugin_mod.run_build(plugin)
					logger.info("updated " .. plugin.name .. " (" .. #log_entries .. " commits)")
				else
					logger.info(plugin.name .. " already up to date")
				end
				state.set_status(plugin.name, state.STATUS.INSTALLED)
			else
				state.set_status(plugin.name, state.STATUS.ERROR, err)
				logger.error("failed to update " .. plugin.name .. ": " .. tostring(err))
			end

			events.emit("update_done", plugin, ok, log_entries)
			on_done(ok, log_entries)
		end,
	})
end

--- Update all installed, version-unpinned plugins.
---@param plugins table<string, table>
---@param on_done function(results: table<string, {ok: boolean, log: string[]|nil}>)|nil
function M.update(plugins, on_done)
	local jobs = require("goopy.jobs")
	local tasks = {}
	local names = {}

	for name, plugin in pairs(plugins) do
		-- skip plugins pinned to a specific commit
		if not plugin.commit and git.is_repo(plugin.dir) then
			table.insert(names, name)
			table.insert(tasks, function(done)
				update_one(plugin, function(ok, log)
					done({ ok = ok, log = log })
				end)
			end)
		end
	end

	if #tasks == 0 then
		logger.info("nothing to update")
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

--- Update a single named plugin.
---@param plugins table<string, table>
---@param name string
---@param on_done function(ok: boolean, log: string[]|nil)|nil
function M.update_one(plugins, name, on_done)
	local plugin = plugins[name]
	if not plugin then
		logger.error("goopy: unknown plugin '" .. name .. "'")
		if on_done then
			on_done(false, nil)
		end
		return
	end

	update_one(plugin, function(ok, log)
		require("goopy.lockfile").write(plugins)
		if on_done then
			on_done(ok, log)
		end
	end)
end

return M
