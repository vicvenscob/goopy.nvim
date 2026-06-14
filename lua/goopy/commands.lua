local installer = require("goopy.installer")
local updater = require("goopy.updater")
local ui = require("goopy.ui")
local loader = require("goopy.loader")

local M = {}

function M.setup()
  vim.api.nvim_create_user_command("GoopyInstall", function(opts)
    local names = #opts.fargs > 0 and opts.fargs or nil
    installer.install(names)
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("GoopyUpdate", function(opts)
    local names = #opts.fargs > 0 and opts.fargs or nil
    updater.update(names)
  end, { nargs = "*" })

  vim.api.nvim_create_user_command("GoopySync", function()
    require("goopy").sync()
  end, {})

  vim.api.nvim_create_user_command("GoopyClean", function()
    require("goopy").clean()
  end, {})

  vim.api.nvim_create_user_command("GoopyReload", function(opts)
    if opts.args ~= "" then
      loader.reload(opts.args)
    end
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("GoopyStatus", function()
    ui.status()
  end, {})

  vim.api.nvim_create_user_command("GoopyLog", function()
    ui.log()
  end, {})
end

return M
