local M = {}

local listeners = {}

--- Subscribe to an internal goopy event.
---@param event string
---@param fn function
function M.on(event, fn)
	listeners[event] = listeners[event] or {}
	table.insert(listeners[event], fn)
end

--- Emit an internal goopy event to all listeners.
---@param event string
---@param ... any
function M.emit(event, ...)
	for _, fn in ipairs(listeners[event] or {}) do
		local ok, err = pcall(fn, ...)
		if not ok then
			require("goopy.logger").error("event handler for '" .. event .. "' failed: " .. tostring(err))
		end
	end
end

--- Remove all listeners for an event, or all listeners entirely.
---@param event string|nil
function M.clear(event)
	if event then
		listeners[event] = nil
	else
		listeners = {}
	end
end

return M
