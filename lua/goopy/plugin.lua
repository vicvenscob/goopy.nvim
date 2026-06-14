local paths = require("goopy.paths")

local M = {}

local LOAD_KEYS = { "event", "cmd", "ft", "keys", "module" }

--- Derive a plugin's name from its repo string ("owner/repo" -> "repo").
---@param repo string
---@return string
local function derive_name(repo)
	return repo:match("([^/]+)$"):gsub("%.nvim$", ""):gsub("%.lua$", "")
end

--- Determine whether a spec should be lazily loaded based on its loading keys.
---@param spec table
---@return boolean
local function is_lazy(spec)
	if spec.lazy ~= nil then
		return spec.lazy
	end
	if spec.startup then
		return false
	end
	if spec.manual then
		return true
	end
	for _, key in ipairs(LOAD_KEYS) do
		if spec[key] ~= nil then
			return true
		end
	end
	return false
end

--- Normalize a raw user spec (string or table) into a full plugin object.
---@param raw string|table
---@return table
function M.normalize(raw)
	local spec = type(raw) == "string" and { raw } or vim.deepcopy(raw)

	-- positional repo: { "owner/repo", ... }
	local repo = spec.repo or spec[1]
	assert(repo, "goopy: plugin spec missing 'repo'")

	local name = spec.name or derive_name(repo)

	local plugin = {
		repo = repo,
		name = name,
		dependencies = spec.dependencies or {},
		optional = spec.optional or false,
		version = spec.version,
		branch = spec.branch,
		commit = spec.commit,
		tag = spec.tag,
		priority = spec.priority or 50,
		enabled = spec.enabled,

		-- loading triggers
		event = spec.event,
		cmd = spec.cmd,
		ft = spec.ft,
		keys = spec.keys,
		module = spec.module,
		startup = spec.startup or false,
		manual = spec.manual or false,

		-- hooks
		init = spec.init,
		config = spec.config,
		build = spec.build,
		uninstall = spec.uninstall,

		-- raw opts passed to config()
		opts = spec.opts,
	}

	-- resolve "enabled" if it's a function
	if type(plugin.enabled) == "function" then
		plugin.enabled = plugin.enabled()
	elseif plugin.enabled == nil then
		plugin.enabled = true
	end

	plugin.lazy = is_lazy(plugin)
	plugin.dir = paths.install_dir(plugin.name, plugin.lazy)

	return plugin
end

--- Normalize a list of raw specs.
---@param raw_specs table
---@return table[]
function M.normalize_all(raw_specs)
	local out = {}
	for _, raw in ipairs(raw_specs) do
		table.insert(out, M.normalize(raw))
	end
	return out
end

--- Run a plugin's build hook (string = shell cmd in plugin dir, function = lua callback).
---@param plugin table
function M.run_build(plugin)
	if not plugin.build then
		return
	end
	if type(plugin.build) == "function" then
		local ok, err = pcall(plugin.build, plugin)
		if not ok then
			require("goopy.logger").error("build() failed for " .. plugin.name .. ": " .. tostring(err))
		end
	elseif type(plugin.build) == "string" then
		local jobs = require("goopy.jobs")
		-- ":<lua function>" convention, like lazy.nvim, for running lua build steps as strings
		if plugin.build:sub(1, 1) == ":" then
			local ok, err = pcall(vim.cmd, plugin.build:sub(2))
			if not ok then
				require("goopy.logger").error("build() failed for " .. plugin.name .. ": " .. tostring(err))
			end
			return
		end
		jobs.run(vim.split(plugin.build, " "), {
			cwd = plugin.dir,
			on_done = function(ok, _, err)
				if not ok then
					require("goopy.logger").error("build() failed for " .. plugin.name .. ": " .. err)
				end
			end,
		})
	end
end

--- Run init() hook (before plugin is loaded onto runtimepath).
---@param plugin table
function M.run_init(plugin)
	if plugin.init then
		local ok, err = pcall(plugin.init, plugin)
		if not ok then
			require("goopy.logger").error("init() failed for " .. plugin.name .. ": " .. tostring(err))
		end
	end
end

--- Run config() hook (after plugin is loaded onto runtimepath).
---@param plugin table
function M.run_config(plugin)
	if plugin.config == false then
		return
	end
	if type(plugin.config) == "function" then
		local ok, err = pcall(plugin.config, plugin.opts or {})
		if not ok then
			require("goopy.logger").error("config() failed for " .. plugin.name .. ": " .. tostring(err))
		end
	elseif plugin.opts then
		-- default: call require(module).setup(opts)
		local mod_name = plugin.module or plugin.name
		local ok, mod = pcall(require, mod_name)
		if ok and mod.setup then
			mod.setup(plugin.opts)
		end
	end
end

return M
