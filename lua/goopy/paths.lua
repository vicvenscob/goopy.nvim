local M = {}

M.data = vim.fn.stdpath("data") .. "/goopy"
M.start = M.data .. "/start"
M.opt = M.data .. "/opt"
M.lockfile = M.data .. "/goopy-lock.json"
M.log = vim.fn.stdpath("log") .. "/goopy.log"

--- Returns the install directory for a plugin based on its load mode.
---@param name string
---@param lazy boolean
---@return string
function M.install_dir(name, lazy)
	return (lazy and M.opt or M.start) .. "/" .. name
end

--- Ensure all goopy directories exist.
function M.ensure_dirs()
	for _, dir in ipairs({ M.data, M.start, M.opt }) do
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
	end
end

return M
