local paths = require("goopy.paths")

local M = {}

local levels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
M.level = levels.INFO

local function write(level_name, level, msg)
	if level < M.level then
		return
	end
	local line = string.format("[%s] %s %s\n", level_name, os.date("%Y-%m-%d %H:%M:%S"), msg)
	local f = io.open(paths.log, "a")
	if f then
		f:write(line)
		f:close()
	end
	if level >= levels.WARN then
		vim.schedule(function()
			vim.notify("[goopy] " .. msg, level == levels.ERROR and vim.log.levels.ERROR or vim.log.levels.WARN)
		end)
	end
end

function M.debug(msg)
	write("DEBUG", levels.DEBUG, msg)
end

function M.info(msg)
	write("INFO", levels.INFO, msg)
end

function M.warn(msg)
	write("WARN", levels.WARN, msg)
end

function M.error(msg)
	write("ERROR", levels.ERROR, msg)
end

--- Read the full log file contents.
---@return string[]
function M.read()
	local f = io.open(paths.log, "r")
	if not f then
		return {}
	end
	local lines = {}
	for line in f:lines() do
		table.insert(lines, line)
	end
	f:close()
	return lines
end

--- Clear the log file.
function M.clear()
	local f = io.open(paths.log, "w")
	if f then
		f:close()
	end
end

return M
