--[[
===============================================================================================
Plugin: incline.nvim
===============================================================================================
Description: Mostra il nome del file corrente in una finestra flottante ancorata a ogni
             finestra, come sostituto minimale del winbar (disattivato in heirline.lua).
Status: Active
Author: b0o
Repository: https://github.com/b0o/incline.nvim
Notes:
 - Caricamento lazy su BufReadPre
 - Colori letti dinamicamente da sphynx.colors (coerenti col colorscheme attivo) e
   riapplicati sull'evento ColorScheme (augroup dedicato), come in tabby.lua
 - Icona del file da nvim-web-devicons, indicatore "[+] " se il buffer è modificato
 - Mostra sempre il path relativo alla cwd (abbreviato con pathshorten oltre il 60%
   della larghezza finestra)
 - Sfondo pill attivo fisso a "#5280AE" (non colors.blue): colors.blue è anche il colore
   di più icone in devicons.lua (lua, css, ts, ecc.), che risulterebbero invisibili sullo
   sfondo attivo se coincidessero
===============================================================================================
--]]

local M = {}

M.plugins = {
    ["incline"] = {
        "b0o/incline.nvim",
        lazy = true,
        event = "BufReadPre",
        dependencies = { "kyazdani42/nvim-web-devicons" },
    },
}
local function setup_incline()
    local colors = require("sphynx.colors").get_color()
    -- require di incline.helpers va fatto qui dentro (non a livello di modulo): questo file
    -- viene richiesto all'avvio, prima che lazy.nvim installi incline.nvim sul runtimepath.
    local helpers = require("incline.helpers")

    local function darken(hex, pct)
        local rgb = helpers.hex_to_rgb(hex)
        local factor = 1 - pct
        return helpers.rgb_to_hex({ r = rgb.r * factor, g = rgb.g * factor, b = rgb.b * factor })
    end

    require("incline").setup({
        highlight = {
            groups = {
                InclineNormal = {
                    default = true,
                    guibg = darken(vim.g.colors_name == "nordfox" and colors.blue or colors.grey13, 0.4),
                },
                InclineNormalNC = {
                    default = true,
                    guifg = colors.grey7,
                    guibg = colors.bg1
                },
            },
        },
        debounce_threshold = { rising = 150, falling = 300 },
        window = {
          padding = 0,
          margin = { horizontal = 0, vertical = 0 },
        },
        hide = {
            cursorline = false,
            only_win = true,
        },
        ignore = {
            buftypes = {},
            filetypes = { 'neo-tree' },
        },
        render = function(props)
            local bufname = vim.api.nvim_buf_get_name(props.buf)
            local filename = vim.fn.fnamemodify(bufname, ":t")
            if filename == "" then
                filename = "[No Name]"
            end
            local display = filename

            if bufname ~= "" then
                display = vim.fn.fnamemodify(bufname, ":.") -- path relativo alla cwd
                local max_width = math.floor(vim.api.nvim_win_get_width(props.win) * 0.6)
                if #display > max_width then
                    display = vim.fn.pathshorten(display) -- es. lua/sphynx/plugins/incline.lua -> l/s/p/incline.lua
                end
            end

            local ft_icon, ft_color = require("nvim-web-devicons").get_icon_color(filename)
            local modified = vim.bo[props.buf].modified
            local buffer = {
                ft_icon and {
                    " ",
                    ft_icon,
                    " ",
                    -- guibg = ft_color,
                    -- guifg = helpers.cont
                    guibg = props.focused and darken(ft_color, 0.2) or darken(ft_color, 0.6),
                    guifg = props.focused and helpers.contrast_color(ft_color) or darken(helpers.contrast_color(ft_color), 0.6),
                } or "",
                " ",
                { display, gui = modified and "bold,italic" or "bold" },
                " ",
            }
            return buffer
      end,

    })
end

M.configs = {
    ["incline"] = function()
        setup_incline()

        local augroup = vim.api.nvim_create_augroup("InclineColorScheme", { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = augroup,
            pattern = "*",
            callback = function()
                vim.schedule(setup_incline)
            end,
        })
    end,
}

return M

