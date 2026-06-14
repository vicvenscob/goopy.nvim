local M = {}

--- Register a package.preload hook so require(module) triggers plugin load.
---@param plugin table
---@param loader table the goopy.loader module
function M.register(plugin, loader)
	local modules = plugin.module
	if type(modules) == "string" then
		modules = { modules }
	end

	for _, mod_name in ipairs(modules) do
		-- preload hook: when this module (or a submodule of it) is required,
		-- load the plugin first, then defer to the real loader.
		package.preload[mod_name] = function(...)
			package.preload[mod_name] = nil
			loader.load(plugin.name)
			return require(mod_name)
		end

		-- also handle submodules e.g. require("foo.bar") triggering on "foo"
		local searcher = function(name)
			if name == mod_name or name:match("^" .. vim.pesc(mod_name) .. "%.") then
				package.preload[name] = nil
				loader.load(plugin.name)
				return loadstring and nil or nil -- defer to normal searchers after load
			end
			return nil
		end

		table.insert(package.loaders, 2, function(name)
			local res = searcher(name)
			if res then
				return res
			end
			if name == mod_name or name:match("^" .. vim.pesc(mod_name) .. "%.") then
				if not require("goopy.state").is_loaded(plugin.name) then
					loader.load(plugin.name)
				end
			end
			return nil
		end)
	end
end

return M
