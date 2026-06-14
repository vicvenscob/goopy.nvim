local jobs = require("goopy.jobs")

local M = {}

function M.clone(repo, dest, opts, cb)
  opts = opts or {}
  local url = "https://github.com/" .. repo .. ".git"
  local cmd = { "git", "clone", "--filter=blob:none", "--recurse-submodules" }

  if opts.branch then
    vim.list_extend(cmd, { "--branch", opts.branch })
  end

  vim.list_extend(cmd, { url, dest })

  jobs.run(cmd, {
    on_exit = function(code, out, err)
      cb(code == 0, code == 0 and out or err)
    end,
  })
end

function M.checkout(dest, ref, cb)
  jobs.run({ "git", "checkout", ref }, {
    cwd = dest,
    on_exit = function(code, out, err)
      cb(code == 0, code == 0 and out or err)
    end,
  })
end

function M.fetch(dest, cb)
  jobs.run({ "git", "fetch", "--all", "--tags" }, {
    cwd = dest,
    on_exit = function(code, out, err)
      cb(code == 0, code == 0 and out or err)
    end,
  })
end

function M.pull(dest, cb)
  jobs.run({ "git", "pull", "--ff-only" }, {
    cwd = dest,
    on_exit = function(code, out, err)
      cb(code == 0, code == 0 and out or err)
    end,
  })
end

function M.rev_parse(dest, ref, cb)
  jobs.run({ "git", "rev-parse", ref or "HEAD" }, {
    cwd = dest,
    on_exit = function(code, out, _)
      cb(code == 0 and out[1] or nil)
    end,
  })
end

return M
