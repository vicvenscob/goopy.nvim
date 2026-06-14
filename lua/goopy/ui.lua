local state = require("goopy.state")
local config = require("goopy.config")

local M = {}

--- Build the lines for the status window.
---@return string[] lines
---@return table<number, string> highlights line number -> hl group
local function build_status_lines()
	local icons = config.options.ui.icons
	local lines = { "Goopy Plugin Status", "" }
	local highlights = {}

	local entries = {}
	for name, entry in pairs(state.all()) do
		table.insert(entries, { name = name, entry = entry })
	end
	table.sort(entries, function(a, b)
		return a.name < b.name
	end)

	for _, item in ipairs(entries) do
		local entry = item.entry
		local icon, hl

		if entry.status == state.STATUS.ERROR then
			icon, hl = icons.error, "ErrorMsg"
		elseif entry.loaded then
			icon, hl = icons.loaded, "DiagnosticOk"
		elseif entry.status == state.STATUS.INSTALLED then
			icon, hl = icons.installed, "Comment"
		else
			icon, hl = icons.pending, "WarningMsg"
		end

		local lazy_info = entry.plugin.lazy and " [lazy]" or ""
		local commit_info = entry.commit and (" (" .. entry.commit:sub(1, 7) .. ")") or ""
		local line = string.format("  %s %s%s%s", icon, item.name, lazy_info, commit_info)

		table.insert(lines, line)
		highlights[#lines] = hl

		if entry.error then
			table.insert(lines, "      " .. tostring(entry.error))
			highlights[#lines] = "ErrorMsg"
		end
	end

	return lines, highlights
end

--- Open a floating window showing plugin status.
function M.status()
	local lines, highlights = build_status_lines()

	local width = math.min(80, math.max(40, vim.o.columns - 10))
	local height = math.min(#lines + 2, vim.o.lines - 4)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "goopy"

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " goopy.nvim ",
		title_pos = "center",
	})

	for line_num, hl in pairs(highlights) do
		vim.api.nvim_buf_add_highlight(buf, -1, hl, line_num - 1, 0, -1)
	end

	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
	vim.keymap.set("n", "<esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })

	return win, buf
end

--- Open a floating window showing the goopy log.
function M.log()
	local logger = require("goopy.logger")
	local lines = logger.read()
	if #lines == 0 then
		lines = { "(log is empty)" }
	end

	local width = math.min(100, math.max(50, vim.o.columns - 10))
	local height = math.min(#lines + 2, vim.o.lines - 4)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "log"

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " goopy.nvim log ",
		title_pos = "center",
	})

	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
	vim.keymap.set("n", "<esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })

	return win, buf
end

return M
