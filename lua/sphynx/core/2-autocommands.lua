local utils = require("sphynx.utils")

utils.define_augroups({
    _general = {
        {
            event = { "VimEnter" },
            opts = {
                pattern = "*",
                callback = function()
                    vim.api.nvim_set_current_dir(vim.fn.expand("%:p:h"))
                end,
                desc = "When open Neovim with file set current dir to file",
            },
        },
        {
            event = { "VimEnter", "DirChangedPre" },
            opts = {
                pattern = "*",
                callback = utils.set_shell_title,
                desc = "Set shell title",
            },
        },
        {
            event = { "BufEnter", "ShellCmdPost", "FocusGained" },
            opts = {
                pattern = "*",
                callback = utils.check_time,
                desc = "Check time",
            },
        },
        {
            event = { "VimEnter", "DirChanged" },
            opts = {
                pattern = "*",
                callback = function()
                    -- Windows: named pipe; Unix: socket in XDG_RUNTIME_DIR.
                    -- pcall: al secondo nvim sulla stessa cartella il nome e'
                    -- gia' preso e serverstart solleva un errore.
                    local nome = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
                    local socket
                    if vim.fn.has("win32") == 1 then
                        socket = [[\\.\pipe\claude-debug-]] .. nome
                    else
                        socket = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/claude-debug-" .. nome
                    end
                    pcall(vim.fn.serverstart, socket)
                    -- socket fisso: Claude lo trova qualunque sia la cartella di Neovim
                    local fisso = vim.fn.has("win32") == 1 and [[\\.\pipe\claude-nvim]]
                        or (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/claude-nvim"
                    pcall(vim.fn.serverstart, fisso)
                end,
                desc = "Socket per-progetto per l'MCP neovim di Claude",
            },
        },
        {
            event = "TextYankPost",
            opts = {
                pattern = "*",
                callback = function()
                    vim.hl.on_yank({ higroup = "IncSearch", timeout = 1000, on_visual = true })
                end,
                desc = "Highlight on yank",
            },
        },
        {
            event = "BufReadPost",
            opts = {
                pattern = "*",
                callback = function()
                    vim.cmd([[if line("'\"") > 1 && line("'\"") <= line("$") | execute "normal! g`\"" | endif]])
                end,
                desc = "Go to last loc when opening a buffer",
            },
        },
        {
            event = "QuickFixCmdPost",
            opts = {
                pattern = "*",
                callback = function()
                    vim.cmd("copen | wincmd J")
                end,
                desc = "Open quickfix bottom",
            },
        },
    },
    _filetype_setting = {
        {
            event = "filetype",
            opts = {
                pattern = "json",
                command = [[syntax match comment +\/\/.\+$+ | setlocal conceallevel=0]],
                desc = "Setting for json file",
            },
        },
        {
            event = { "BufEnter", "BufFilePost" },
            opts = {
                pattern = "*.ahk",
                callback = function()
                    vim.api.nvim_set_option_value("commentstring", "; %s", { buf = 0 })
                end,
                desc = "Setting ",
            },
        },
    },
    _options = {
        {
            event = "BufWritePost",
            opts = {
                pattern = "1-settings.lua",
                callback = reload_options,
                desc = "Reload config nvim",
            },
        },
    },
})

if sphynx.config.cursorline then
    utils.define_augroups({
        _cursorline = {
            {
                event = { "InsertLeave", "WinEnter" },
                opts = {
                    pattern = "*",
                    command = [[set cursorline]],
                    nested = true,
                    desc = "Enable cursorline",
                },
            },
            {
                event = { "InsertEnter", "WinLeave" },
                opts = {
                    pattern = "*",
                    command = [[set nocursorline]],
                    nested = true,
                    desc = "Disable cursorline",
                },
            },
        },
    })
end

if sphynx.config.auto_save_buffer then
    utils.define_augroups({
        _autosave = {
            {
                event = "FocusLost",
                opts = {
                    pattern = "*",
                    command = [[silent! wall]],
                    nested = true,
                    desc = "Save file automatic",
                },
            },
        },
    })
end
