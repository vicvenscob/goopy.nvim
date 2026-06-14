if vim.g.loaded_goopy then
	return
end
vim.g.loaded_goopy = 1

-- goopy.nvim does not auto-run setup() here; the user calls
-- require("goopy").setup({ plugins = { ... } }) from their config.
-- This file exists as a hook point for future bootstrap logic
-- (e.g. self-bootstrapping goopy itself via git on first launch).
