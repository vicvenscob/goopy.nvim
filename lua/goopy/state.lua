local git = require("goopy.git")

local M = {}

--- @type table<string, table> name -> { status, loaded, error }
M.plugins = {}

local STATUS = {
	NOT_INSTALLED = "not_installed",
	INSTALLED = "installed",
	INSTALLING = "installing",
	UPDATING = "updating",
	ERROR = "error",
}
M.STATUS = STATUS

--- Register a plugin into state, computing its initial install status.
---@param plugin table
function M.register(plugin)
	local status = git.is_repo(plugin.dir) and STATUS.INSTALLED or STATUS.NOT_INSTALLED
	M.plugins[plugin.name] = {
		plugin = plugin,
		status = status,
		loaded = false,
		error = nil,
		commit = status == STATUS.INSTALLED and git.head(plugin.dir) or nil,
	}
end

--- Register all plugins.
---@param plugins table<string, table>
function M.register_all(plugins)
	for _, plugin in pairs(plugins) do
		M.register(plugin)
	end
end

--- Mark a plugin's status.
---@param name string
---@param status string
---@param err string|nil
function M.set_status(name, status, err)
	if not M.plugins[name] then
		return
	end
	M.plugins[name].status = status
	M.plugins[name].error = err
	if status == M.STATUS.INSTALLED then
		M.plugins[name].commit = git.head(M.plugins[name].plugin.dir)
	end
end

--- Mark a plugin as loaded.
---@param name string
function M.set_loaded(name)
	if M.plugins[name] then
		M.plugins[name].loaded = true
	end
end

--- Get state entry for a plugin.
---@param name string
---@return table|nil
function M.get(name)
	return M.plugins[name]
end

--- Get all state entries.
---@return table<string, table>
function M.all()
	return M.plugins
end

--- Returns true if a plugin is currently loaded.
---@param name string
---@return boolean
function M.is_loaded(name)
	local entry = M.plugins[name]
	return entry ~= nil and entry.loaded
end

return M
