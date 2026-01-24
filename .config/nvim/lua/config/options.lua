-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.clipboard = "unnamedplus"

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

vim.opt.list = true
vim.opt.listchars = {
  tab = "▸ ",
  trail = "•",
  nbsp = "␣",
  extends = "❯",
  precedes = "❮",
  eol = "↲",
}

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"

vim.opt.signcolumn = "yes"

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.termguicolors = true

vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.fileencoding = "utf-8"
