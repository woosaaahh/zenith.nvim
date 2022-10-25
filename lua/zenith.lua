local M = {}
M.back_win_id, M.main_win_id = nil, nil

--- Options --------------------------------------------------------------------

local options = {
	nvim = {
		cmdheight = 1,
		colorcolumn = false,
		foldcolumn = "0",
		laststatus = 0,
		number = false,
		relativenumber = false,
		ruler = false,
		scrolloff = 0,
		shortmess = "acsF",
		showcmd = false,
		showmode = false,
		sidescrolloff = 0,
		signcolumn = "no",
		wrap = false,
	},

	-- on_open = function()
	-- 	print("Zenith mode one")
	-- end,
	-- on_close = function()
	-- 	print("Zenith mode off")
	-- end,
}

local prev_opts = {}
for opt, _ in pairs(options.nvim) do
	prev_opts[opt] = vim.o[opt]
end

local function set_options(opts)
	for opt, val in pairs(opts) do
		vim.o[opt] = val
	end
end

--- Highlights -----------------------------------------------------------------

local function prepare_highlights()
	vim.cmd("highlight default link ZenithNormal Normal")
	vim.cmd("highlight default link ZenithBorder FloatBorder")
end
prepare_highlights()

local function force_highlights(win_id)
	local cwin_id = vim.api.nvim_get_current_win()
	if cwin_id ~= win_id then
		vim.api.nvim_set_current_win(win_id)
	end

	vim.wo.winhighlight = "EndOfBuffer:ZenithNormal,FloatBorder:ZenithBorder,NormalFloat:ZenithNormal"

	vim.api.nvim_set_current_win(cwin_id)
end

--- AutoCmds -------------------------------------------------------------------

local augroup = vim.api.nvim_create_augroup("Zenith", { clear = true })

local function create_autocmds()
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = augroup,
		desc = "Update main window when switching buffers",
		callback = function()
			if vim.api.nvim_get_current_win() == M.main_win_id then
				vim.api.nvim_win_set_config(M.main_win_id, M.get_main_win_opts())
				vim.wo.winhighlight = "EndOfBuffer:ZenithNormal,FloatBorder:ZenithBorder,NormalFloat:ZenithNormal"
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		desc = "Set options after entering buffer",
		callback = function()
			if vim.api.nvim_get_current_win() == M.main_win_id then
				if options.on_open and type(options.on_open) == "function" then
					set_options(options.nvim)
					options.on_open()
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufLeave", {
		group = augroup,
		desc = "Reset options after leaving buffer",
		callback = function()
			if vim.api.nvim_get_current_win() == M.main_win_id then
				if options.on_close and type(options.on_close) == "function" then
					set_options(prev_opts)
					options.on_close()
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		group = augroup,
		pattern = string.format("%d", M.main_win_id),
		desc = "Close background window when main window is closed",
		callback = M.close,
	})

	vim.api.nvim_create_autocmd({ "CmdWinEnter", "CmdWinLeave" }, {
		group = augroup,
		desc = "Adjust windows height when the command line window is open/closed",
		callback = function(args)
			M.resize(args.event)
		end,
	})

	vim.api.nvim_create_autocmd("CursorHold", {
		group = augroup,
		desc = "Clear command line and search highlights after some time",
		callback = function()
			vim.defer_fn(function()
				vim.api.nvim_echo({}, false, {})
				vim.cmd("nohlsearch")
			end, 1000)
		end,
	})
end

--- Windows -------------------------------------------------------------------

local function get_back_win_opts()
	return {
		col = 0,
		focusable = false,
		height = vim.o.lines,
		relative = "editor",
		row = 0,
		style = "minimal",
		width = vim.o.columns,
		zindex = 1,
	}
end

local function on_open()
	create_autocmds()
	set_options(options.nvim)
	if options.on_open and type(options.on_open) == "function" then
		options.on_open()
	end
end

local function on_close()
	vim.api.nvim_clear_autocmds({ group = augroup })
	set_options(prev_opts)
	if options.on_close and type(options.on_close) == "function" then
		options.on_close()
	end
end

--- Exported -------------------------------------------------------------------

function M.get_main_win_opts()
	local width = math.max(80, vim.o.textwidth)
	return {
		border = "single",
		col = math.floor((vim.o.columns - width) / 2),
		focusable = true,
		height = vim.o.lines,
		relative = "editor",
		row = 0,
		style = "minimal",
		width = width,
		zindex = 2,
	}
end

function M.open()
	M.back_win_id = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, get_back_win_opts())
	force_highlights(M.back_win_id)

	M.main_win_id = vim.api.nvim_open_win(vim.api.nvim_get_current_buf(), true, M.get_main_win_opts())
	force_highlights(M.main_win_id)

	on_open()
end

function M.close()
	if M.back_win_id then
		M.back_win_id = vim.api.nvim_win_close(M.back_win_id, true)
	end

	if M.main_win_id then
		M.main_win_id = vim.api.nvim_win_close(M.main_win_id, true)
	end

	on_close()
end

function M.resize(event)
	if event == "CmdWinEnter" then
		vim.api.nvim_win_set_height(M.back_win_id, vim.o.lines - vim.o.cmdheight - vim.o.cmdwinheight)
		vim.api.nvim_win_set_height(M.main_win_id, vim.o.lines - vim.o.cmdheight - vim.o.cmdwinheight - 2)
	elseif event == "CmdWinLeave" then
		vim.api.nvim_win_set_height(M.back_win_id, vim.o.lines - vim.o.cmdheight)
		vim.api.nvim_win_set_height(M.main_win_id, vim.o.lines - vim.o.cmdheight)
	end
end

function M.toggle()
	if M.back_win_id or M.main_win_id then
		M.close()
	else
		M.open()
	end
end

function M.setup(opts)
	if type(opts) == "table" then
		options = vim.tbl_deep_extend("force", options, opts)
	end
end

return M
