-- Minimal Neovim config: familiar save/quit keys on top of the defaults.

vim.g.mapleader = " "

-- Ctrl+S saves in every mode and returns to normal mode.
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<Esc><cmd>write<cr>", { desc = "Save" })

-- Ctrl+Q quits; Neovim still refuses if there are unsaved changes.
vim.keymap.set({ "n", "i", "v" }, "<C-q>", "<Esc><cmd>quit<cr>", { desc = "Quit" })

-- yy / p share the system clipboard.
vim.opt.clipboard = "unnamedplus"

vim.opt.number = true
