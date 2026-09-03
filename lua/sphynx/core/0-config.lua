local utils = require("sphynx.utils")

local config = {}

function config.load()
    sphynx.config = {
        -- Auto save Buffer
        auto_save_buffer = true,
        cursorline = true,
        -- theme style to use
        -- • nightfox
        -- • nightfox
        -- • dayfox
        -- • dawnfox
        -- • duskfox
        -- • nordfox
        -- • terafox
        -- • carbonfox
        -- • onenord
        colorscheme = "nightfox",
        -- Whether the background is transparent
        -- • boolean
        transparent_background = false,
        -- lint configuration file
        -- • string
        nvim_lint_dir = utils.join_path(sphynx.path.nvim_config, "lint"),
        -- Code snippet storage directory
        -- • string
        code_snippets_directory = vim.fn.expand(vim.fn.stdpath("data") .. "/snippet"),
        ui = {
            tabufline = {
                enabled = true,
                lazyload = true,
                order = { "treeOffset", "buffers", "tabs", "btns" },
                modules = nil,
                bufwidth = 21,
            },
        },
        excluded_filetypes = {
            "help",
            "git",
            "nerdtree",
            "vista",
            "Trouble",
            "NvimTree",
            "neoterm",
            "qf",
            "TelescopePrompt",
            "packer",
            "lspinfo",
            "snippets",
            "noice",
            "gitcommit",
            "fugitive",
            "GrepperSide",
        },
        border_style = {
            { "╭", "NordCmdlineBorder" },
            { "─", "NordCmdlineBorder" },
            { "╮", "NordCmdlineBorder" },
            { "│", "NordCmdlineBorder" },
            { "╯", "NordCmdlineBorder" },
            { "─", "NordCmdlineBorder" },
            { "╰", "NordCmdlineBorder" },
            { "│", "NordCmdlineBorder" },
        },
        -- Plugin utilizzato per autocompletem
        -- cmp
        -- blink
        autocomplete = "blink",
    }
end

return config
