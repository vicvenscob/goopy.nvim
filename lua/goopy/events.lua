local M = {}

local listeners = {}

function M.on(name, fn)
  listeners[name] = listeners[name] or {}
  table.insert(listeners[name], fn)
end

function M.emit(name, ...)
  for _, fn in ipairs(listeners[name] or {}) do
    local ok, err = pcall(fn, ...)
    if not ok then
      require("goopy.logger").error("event '" .. name .. "' handler failed: " .. tostring(err))
    end
  end
end

return M
