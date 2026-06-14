local M = {}

--- Build a dependency graph and return plugins in topological + priority order.
--- Plugins with higher `priority` load earlier among those with no remaining deps.
---@param plugins table<string, table> name -> plugin
---@return table[] ordered list of plugins
---@return string[]|nil cycle if a cycle is detected, the list of plugin names involved
function M.sort(plugins)
	local in_degree = {}
	local dependents = {} -- name -> list of plugins that depend on it

	for name, _ in pairs(plugins) do
		in_degree[name] = 0
		dependents[name] = {}
	end

	for name, plugin in pairs(plugins) do
		for _, dep in ipairs(plugin.dependencies) do
			local dep_name = type(dep) == "table" and (dep.name or require("goopy.plugin").normalize(dep).name) or dep
			if plugins[dep_name] then
				in_degree[name] = in_degree[name] + 1
				table.insert(dependents[dep_name], name)
			end
		end
	end

	-- ready queue: deps satisfied, sorted by priority (desc) then name
	local ready = {}
	for name, deg in pairs(in_degree) do
		if deg == 0 then
			table.insert(ready, name)
		end
	end

	local function sort_ready()
		table.sort(ready, function(a, b)
			local pa, pb = plugins[a].priority, plugins[b].priority
			if pa ~= pb then
				return pa > pb
			end
			return a < b
		end)
	end

	local ordered = {}
	sort_ready()

	while #ready > 0 do
		sort_ready()
		local name = table.remove(ready, 1)
		table.insert(ordered, plugins[name])

		for _, dependent in ipairs(dependents[name]) do
			in_degree[dependent] = in_degree[dependent] - 1
			if in_degree[dependent] == 0 then
				table.insert(ready, dependent)
			end
		end
	end

	if #ordered ~= vim.tbl_count(plugins) then
		-- cycle detected: collect remaining names
		local remaining = {}
		for name, deg in pairs(in_degree) do
			if deg > 0 then
				table.insert(remaining, name)
			end
		end
		return ordered, remaining
	end

	return ordered, nil
end

--- Get all dependencies (recursively) of a plugin, in load order.
---@param plugin table
---@param plugins table<string, table>
---@return table[] deps load-ordered list of dependency plugin objects
function M.resolve_deps(plugin, plugins)
	local seen = {}
	local result = {}

	local function visit(p)
		for _, dep in ipairs(p.dependencies) do
			local dep_name = type(dep) == "table" and (dep.name or require("goopy.plugin").normalize(dep).name) or dep
			local dep_plugin = plugins[dep_name]
			if dep_plugin and not seen[dep_name] then
				seen[dep_name] = true
				visit(dep_plugin)
				table.insert(result, dep_plugin)
			end
		end
	end

	visit(plugin)
	return result
end

return M
