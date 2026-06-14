local jobs = require("goopy.jobs")

local M = {}

--- Build the full clone URL from a "owner/repo" shorthand or full URL.
---@param repo string
---@return string
function M.url(repo)
	if repo:match("^https?://") or repo:match("^git@") then
		return repo
	end
	return "https://github.com/" .. repo .. ".git"
end

--- Clone a plugin repo asynchronously.
---@param repo string
---@param dest string
---@param opts table|nil { branch, tag, depth, on_done(ok, out, err) }
function M.clone(repo, dest, opts)
	opts = opts or {}
	local cmd = { "git", "clone", "--depth", tostring(opts.depth or 1) }

	if opts.branch then
		vim.list_extend(cmd, { "--branch", opts.branch })
	elseif opts.tag then
		vim.list_extend(cmd, { "--branch", opts.tag })
	end

	vim.list_extend(cmd, { "--recurse-submodules", "--shallow-submodules" })
	vim.list_extend(cmd, { M.url(repo), dest })

	jobs.run(cmd, { on_done = opts.on_done })
end

--- Fetch + reset/pull a plugin repo asynchronously.
---@param dest string
---@param opts table|nil { branch, on_done(ok, out, err) }
function M.update(dest, opts)
	opts = opts or {}
	jobs.run({ "git", "fetch", "--depth", "1", "--all" }, {
		cwd = dest,
		on_done = function(ok, out, err)
			if not ok then
				if opts.on_done then
					opts.on_done(false, out, err)
				end
				return
			end
			local branch_cmd = { "git", "pull", "--ff-only" }
			if opts.branch then
				vim.list_extend(branch_cmd, { "origin", opts.branch })
			end
			jobs.run(branch_cmd, { cwd = dest, on_done = opts.on_done })
		end,
	})
end

--- Checkout a specific commit/tag/branch synchronously.
---@param dest string
---@param ref string
---@return boolean ok, string err
function M.checkout(dest, ref)
	local ok, _, err = jobs.run_sync({ "git", "checkout", ref }, { cwd = dest })
	return ok, err
end

--- Get the current commit hash of a plugin.
---@param dest string
---@return string|nil
function M.head(dest)
	local ok, out = jobs.run_sync({ "git", "rev-parse", "HEAD" }, { cwd = dest })
	if not ok then
		return nil
	end
	return vim.trim(out)
end

--- Get commit log between two refs (for :GoopyLog / update diffs).
---@param dest string
---@param from string
---@param to string|nil defaults to HEAD
---@return string[]
function M.log(dest, from, to)
	local ok, out = jobs.run_sync({ "git", "log", "--oneline", from .. ".." .. (to or "HEAD") }, { cwd = dest })
	if not ok then
		return {}
	end
	return vim.split(vim.trim(out), "\n", { trimempty = true })
end

--- Check if a directory is a valid git repo.
---@param dest string
---@return boolean
function M.is_repo(dest)
	return vim.fn.isdirectory(dest .. "/.git") == 1
end

return M
