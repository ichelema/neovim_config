local M = {}

M.plugins = {
    ["nightfox"] = {
        "EdenEast/nightfox.nvim",
        lazy = false,
        priority = 1000, -- make sure to load this before all the other start plugins
    },
}

M.configs = {
    ["nightfox"] = function()
        local get_color = require("sphynx.colors").get_color
        local colors = get_color()
        local nightfox_colors = get_color("nightfox")

        local ok, nightfox = pcall(require, "nightfox")
        if not ok then
            return
        end

        local options = {
            -- Percorso stabile tra avvii Neovim da Windows e MSYS2.
            compile_path = vim.fn.stdpath("data") .. "/nightfox",
            styles = {
                comments = "italic",
                keywords = "bold",
                types = "italic,bold",
            },
        }

        local palettes = {
            nightfox = {
                bg1 = "#142433",
            },
        }

        local groups = {
            all = {
                SmoothCursor = { fg = "palette.blue.bright" },
                SmoothCursorTrail1 = { fg = "palette.blue.bright" },
                SmoothCursorTrail2 = { fg = "palette.blue" },
                SmoothCursorTrail3 = { fg = "palette.blue" },
                SmoothCursorTrail4 = { fg = "palette.blue.dim" },
                SmoothCursorTrail5 = { fg = "palette.blue.dim" },
                SmoothCursorTrail6 = { fg = "palette.blue.dim" },
                VirtColumn = { fg = colors.grey12 },
                -- Noice
                NoiceCmdlinePopup = { fg = colors.grey3, bg = colors.bg1 },
                NoiceCmdlinePopupBorder = { fg = colors.cyan, bg = colors.bg1 },
                NordCmdlineBorder = { fg = colors.cyan, bg = colors.bg1 },
                NoiceCmdlinePopupTitle = { fg = colors.cyan, bg = colors.bg1 },
                NoicePopupmenu = { fg = colors.grey3, bg = colors.bg1 },
                NoicePopupmenuBorder = { fg = colors.cyan, bg = colors.bg1 },
                NoicePopupmenuSelected = { fg = colors.grey3, bg = colors.grey12, style = "bold" },
                NoicePopupmenuMatch = { fg = colors.cyan, style = "bold" },
                NoiceScrollbar = { fg = colors.grey8, bg = colors.bg1 },
                NoiceScrollbarThumb = { fg = colors.grey12, bg = colors.grey12 },
                NoicePopup = { fg = colors.grey3, bg = colors.bg1 },
                NoicePopupBorder = { fg = colors.cyan, bg = colors.bg1 },
                -- Blink
                BlinkCmpMenu = { fg = colors.grey3, bg = colors.bg1 },
                BlinkCmpMenuBorder = { fg = colors.cyan, bg = colors.bg1 },
                BlinkCmpMenuSelection = { fg = colors.grey3, bg = colors.grey12, style = "bold" },
                BlinkCmpDoc = { fg = colors.grey3, bg = colors.bg1 },
                BlinkCmpDocBorder = { fg = colors.cyan, bg = colors.bg1 },
                BlinkCmpSignatureHelp = { fg = colors.grey3, bg = colors.bg1 },
                BlinkCmpSignatureHelpBorder = { fg = colors.cyan, bg = colors.bg1 },
            },
            nightfox = {
                LspReferenceText = { fg = nightfox_colors.grey13, bg = nightfox_colors.orange },
            },
        }

        nightfox.setup({
            options = options,
            palettes = palettes,
            groups = groups,
        })
    end,
}

return M
