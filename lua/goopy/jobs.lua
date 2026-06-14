local M = {}

--- Run a shell command asynchronously.
---@param cmd string[]
---@param opts table|nil { cwd, env, on_done(ok, stdout, stderr) }
---@return vim.SystemObj
function M.run(cmd, opts)
	opts = opts or {}
	return vim.system(cmd, {
		cwd = opts.cwd,
		env = opts.env,
		text = true,
	}, function(result)
		local ok = result.code == 0
		if opts.on_done then
			vim.schedule(function()
				opts.on_done(ok, result.stdout, result.stderr, result.code)
			end)
		end
	end)
end

--- Run a shell command synchronously (blocking).
---@param cmd string[]
---@param opts table|nil { cwd, env }
---@return boolean ok, string stdout, string stderr
function M.run_sync(cmd, opts)
	opts = opts or {}
	local result = vim.system(cmd, {
		cwd = opts.cwd,
		env = opts.env,
		text = true,
	}):wait()
	return result.code == 0, result.stdout or "", result.stderr or ""
end

--- Run multiple jobs concurrently, calling on_all_done when all finish.
---@param jobs function[] each fn(done) must call done(ok) when finished
---@param on_all_done function(results: boolean[])
function M.run_all(jobs, on_all_done)
	local total = #jobs
	if total == 0 then
		on_all_done({})
		return
	end
	local results = {}
	local remaining = total
	for i, job in ipairs(jobs) do
		job(function(ok)
			results[i] = ok
			remaining = remaining - 1
			if remaining == 0 then
				on_all_done(results)
			end
		end)
	end
end

return M
