local M = {}

--- Register autocmd-based lazy loading for a plugin's `event` field.
---@param plugin table
---@param loader table the goopy.loader module (passed to avoid circular require)
function M.register(plugin, loader)
  local events = plugin.event
  if type(events) == "string" then
    events = { events }
  end

  for _, ev in ipairs(events) do
    -- support "User CustomEvent" style and "Pattern:Event" style
    local event_name, pattern = ev:match("^(%S+)%s+(.+)$")
    event_name = event_name or ev

    vim.api.nvim_create_autocmd(event_name, {
      pattern = pattern or "*",
      once = true,
      group = vim.api.nvim_create_augroup("Goopy_" .. plugin.name .. "_event", { clear = true }),
      callback = function()
        loader.load(plugin.name)
      end,
    })
  end
end

return M
