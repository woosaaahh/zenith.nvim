- [Requirements](#requirements)
- [Usage](#usage)
- [Configuration](#configuration)

# Zenith

Zenith is a lightweight zen-mode plugin.

## Requirements

To use this plugin, you need :

- to have [Neovim](https://github.com/neovim/neovim)
  [`0.8+`](https://github.com/neovim/neovim/releases) version installed ;
- to add `woosaaahh/zenith.nvim` in your plugin manager configuration ;

Here are some plugin managers :

- [vim-plug](https://github.com/junegunn/vim-plug) ;
- [packer.nvim](https://github.com/wbthomason/packer.nvim) ;
- [paq-nvim](https://github.com/savq/paq-nvim).

## Usage

Just assign `zenith.toggle()` to a keymap and press this keymap.

_e.g._ `vim.keymap.set("n", "<leader>z", require("zenith").toggle)`

## Configuration

Here is the default configuration :

```lua
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
```
