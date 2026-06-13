local paths = require("goopy.paths")
local logger = require("goopy.logger")

local M = {}

function M.load()
  local f = io.open(paths.lockfile, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok then
    logger.warn("failed to parse lockfile, ignoring")
    return {}
  end
  return decoded
end

function M.save(data)
  paths.ensure()
  local f = io.open(paths.lockfile, "w")
  if not f then
    logger.error("failed to write lockfile")
    return false
  end
  f:write(vim.json.encode(data))
  f:close()
  return true
end

function M.update_entry(name, commit)
  local data = M.load()
  data[name] = { commit = commit, updated = os.date("%Y-%m-%dT%H:%M:%S") }
  M.save(data)
end

function M.remove_entry(name)
  local data = M.load()
  data[name] = nil
  M.save(data)
end

return M
