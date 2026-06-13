<div align="center">

# goopy.nvim

**A minimal, dependency-aware plugin manager for Neovim.**

Lazy-loading · async git ops · dependency graph resolution · lockfile support

</div>

---

## ✨ Features

- 🔗 **Dependency graph resolution**: plugins load in correct topological order
- ⚡ **Lazy loading**: by event, command, filetype, keymap, or module
- 🔒 **Lockfile support**: pin and reproduce exact plugin versions
- 🔄 **Full lifecycle**: install, update, sync, clean, reload
- 🪝 **Hooks**: `init`, `config`, `build`, `uninstall`
- 📊 **Status UI**: see what's loaded, installed, or pending
- 🧵 **Async**: all git operations run via non-blocking jobs

## 📦 Installation

### Bootstrap (recommended)

Drop this at the top of your `init.lua`:

```lua
local function bootstrap_goopy()
  local install_path = vim.fn.stdpath("data") .. "/goopy/site/pack/goopy/start/goopy.nvim"

  if vim.fn.isdirectory(install_path) == 0 then
    vim.notify("goopy.nvim: bootstrapping...", vim.log.levels.INFO)
    vim.fn.system({
      "git", "clone", "--filter=blob:none", "--depth=1",
      "https://github.com/vicvenscob/goopy.nvim.git",
      install_path,
    })
  end

  vim.opt.runtimepath:prepend(install_path)
end

bootstrap_goopy()
```

This clones goopy.nvim on first launch and prepends it to the runtimepath, no other plugin manager needed.

## 🚀 Quick Start

```lua
require("goopy").setup({
  spec = {
    -- simple string spec
    "nvim-lua/plenary.nvim",

    -- full spec
    {
      repo = "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      cmd = "Telescope",
      config = function()
        require("telescope").setup({})
      end,
    },

    -- lazy load on filetype
    {
      repo = "nvim-treesitter/nvim-treesitter",
      ft = { "lua", "rust", "python" },
      build = function()
        vim.cmd("TSUpdate")
      end,
      config = function()
        require("nvim-treesitter.configs").setup({
          highlight = { enable = true },
        })
      end,
    },
  },
})
```

Then run `:GoopyInstall` to fetch everything.

## 📖 API Reference

### Setup & Registration

| Function | Description |
|---|---|
| `setup(opts)` | Initialize goopy, register plugin specs |
| `add(spec)` / `use(spec)` | Register a plugin |
| `remove(name)` | Unregister and delete a plugin |

### Lifecycle

| Function | Description |
|---|---|
| `install(names?)` | Install missing plugins (all, or given names) |
| `update(names?)` | Update existing plugins |
| `sync()` | Install + update + clean to match config |
| `clean()` | Remove plugins no longer in config |

### Runtime

| Function | Description |
|---|---|
| `load(name)` | Load a plugin immediately |
| `reload(name)` | Reload a plugin (clears its modules) |
| `list()` | Get the full plugin list |
| `status()` | Get install/load status for all plugins |

## ⚙️ Plugin Spec

```lua
{
  repo         = "owner/repo",     -- GitHub repo (required)
  name         = "custom-name",    -- override derived name
  dependencies = { "owner/dep" },  -- required plugins
  optional     = false,            -- mark as optional dependency
  version      = "1.x",            -- version constraint
  branch       = "main",           -- git branch
  commit       = "abc123",         -- pin to a commit
  tag          = "v1.0.0",         -- pin to a tag
  priority     = 100,              -- higher loads first
  enabled      = true,             -- enable/disable (bool or fn)

  -- Loading triggers (pick one or more; default is startup)
  event   = "VeryLazy",            -- autocmd event(s)
  cmd     = "MyCommand",           -- user command(s)
  ft      = "lua",                 -- filetype(s)
  keys    = "<leader>f",           -- keymap(s)
  module  = "myplugin",            -- on require("myplugin")
  startup = false,                 -- load at startup
  manual  = false,                 -- only via load()

  -- Hooks
  init      = function(plugin) end, -- before loading
  config    = function(plugin) end, -- after loading
  build     = function(plugin) end, -- after install/update
  uninstall = function(plugin) end, -- before removal
}
```

## 🖥️ Commands

| Command | Description |
|---|---|
| `:GoopyInstall [names...]` | Install plugins |
| `:GoopyUpdate [names...]` | Update plugins |
| `:GoopySync` | Sync state with config |
| `:GoopyClean` | Remove unused plugins |
| `:GoopyReload <name>` | Reload a plugin |
| `:GoopyStatus` | Show plugin status UI |
| `:GoopyLog` | View the goopy log |

## 🗂️ Architecture
lua/goopy/
     ├── init.lua       -- public API
     ├── config.lua     -- spec registry
     ├── plugin.lua     -- plugin object normalization
     ├── graph.lua       -- dependency graph / topo sort
     ├── installer.lua  -- install logic
     ├── updater.lua    -- update logic
     ├── loader.lua     -- lazy-loading & runtime load
     ├── git.lua        -- async git operations
     ├── lockfile.lua   -- version lockfile
     ├── state.lua      -- runtime plugin status
     ├── events.lua     -- internal event bus
     ├── jobs.lua       -- async job runner
     ├── logger.lua     -- file logging
     ├── paths.lua      -- path resolution
     ├── commands.lua   -- :Goopy* user commands
     └── ui.lua         -- status/log floating windows
