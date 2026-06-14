local paths = require("goopy.paths")
local git = require("goopy.git")

local M = {}

--- Read the lockfile from disk.
---@return table<string, table> name -> { commit, branch, tag }
function M.read()
	local f = io.open(paths.lockfile, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()

	if content == "" then
		return {}
	end

	local ok, decoded = pcall(vim.json.decode, content)
	if not ok or type(decoded) ~= "table" then
		require("goopy.logger").warn("lockfile is corrupt, ignoring")
		return {}
	end
	return decoded
end

--- Write the lockfile to disk based on current installed plugin state.
---@param plugins table<string, table> name -> plugin
function M.write(plugins)
	local data = {}
	for name, plugin in pairs(plugins) do
		if git.is_repo(plugin.dir) then
			data[name] = {
				repo = plugin.repo,
				commit = git.head(plugin.dir),
				branch = plugin.branch,
				tag = plugin.tag,
			}
		end
	end

	local f = io.open(paths.lockfile, "w")
	if not f then
		require("goopy.logger").error("failed to write lockfile")
		return
	end
	f:write(vim.json.encode(data))
	f:close()
end

--- Restore all plugins to the commits recorded in the lockfile.
---@param plugins table<string, table> name -> plugin
---@param on_done function|nil called with results table { name -> bool }
function M.restore(plugins, on_done)
	local lock = M.read()
	local results = {}
	local jobs = require("goopy.jobs")

	local tasks = {}
	for name, plugin in pairs(plugins) do
		local entry = lock[name]
		if entry and entry.commit and git.is_repo(plugin.dir) then
			table.insert(tasks, function(done)
				jobs.run({ "git", "checkout", entry.commit }, {
					cwd = plugin.dir,
					on_done = function(ok)
						results[name] = ok
						done(ok)
					end,
				})
			end)
		end
	end

	jobs.run_all(tasks, function()
		if on_done then
			on_done(results)
		end
	end)
end

return M
