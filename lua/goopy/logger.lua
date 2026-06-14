local paths = require("goopy.paths")

local M = {}

local levels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
M.level = levels.INFO

local function write(level, msg)
  if levels[level] < M.level then return end
  local line = string.format("[%s] %s %s\n", os.date("%Y-%m-%d %H:%M:%S"), level, msg)
  local f = io.open(paths.log_file, "a")
  if f then
    f:write(line)
    f:close()
  end
end

function M.debug(msg) write("DEBUG", msg) end
function M.info(msg) write("INFO", msg) end
function M.warn(msg) write("WARN", msg) end
function M.error(msg) write("ERROR", msg) end

return M
