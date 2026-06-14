local M = {}

-- run a shell command async, returns job id
-- opts: { cwd, on_exit(code, stdout, stderr), env }
function M.run(cmd, opts)
  opts = opts or {}
  local stdout_lines, stderr_lines = {}, {}

  return vim.fn.jobstart(cmd, {
    cwd = opts.cwd,
    env = opts.env,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      for _, l in ipairs(data) do
        if l ~= "" then table.insert(stdout_lines, l) end
      end
    end,
    on_stderr = function(_, data)
      for _, l in ipairs(data) do
        if l ~= "" then table.insert(stderr_lines, l) end
      end
    end,
    on_exit = function(_, code)
      if opts.on_exit then
        opts.on_exit(code, stdout_lines, stderr_lines)
      end
    end,
  })
end

return M
