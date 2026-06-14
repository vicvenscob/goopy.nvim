local function safe_require(name)
  local ok, mod = pcall(require, name)
  if not ok then
    vim.notify("goopy: failed to load " .. name .. ": " .. tostring(mod), vim.log.levels.ERROR)
    return nil
  end
  return mod
end

local installer = safe_require("goopy.installer")
local updater = safe_require("goopy.updater")
local ui = safe_require("goopy.ui")
local loader = safe_require("goopy.loader")

local M = {}

function M.setup()
  vim.api.nvim_create_user_command("GoopyInstall", function(opts)
    local names = #opts.fargs > 0 and opts.fargs or nil
    if installer then installer.install(names) end
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("GoopyUpdate", function(opts)
    local names = #opts.fargs > 0 and opts.fargs or nil
    if updater then updater.update(names) end
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("GoopySync", function()
    require("goopy").sync()
  end, {})

  vim.api.nvim_create_user_command("GoopyClean", function()
    require("goopy").clean()
  end, {})

  vim.api.nvim_create_user_command("GoopyReload", function(opts)
    if opts.args ~= "" and loader then
      loader.reload(opts.args)
    end
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("GoopyStatus", function()
    if ui then ui.status() end
  end, {})

  vim.api.nvim_create_user_command("GoopyLog", function()
    if ui then ui.log() end
  end, {})

  vim.notify("goopy: commands registered", vim.log.levels.INFO)
end

return M
