local M = {}

M.data_dir = vim.fn.stdpath("data") .. "/goopy"
M.pack_dir = M.data_dir .. "/site/pack/goopy/opt"
M.lockfile = M.data_dir .. "/goopy-lock.json"
M.log_file = M.data_dir .. "/goopy.log"

function M.ensure()
  for _, dir in ipairs({ M.data_dir, M.pack_dir }) do
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end
end

function M.plugin_path(name)
  return M.pack_dir .. "/" .. name
end

return M
