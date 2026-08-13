--[[
===============================================================================================
Plugin: rainbow-delimiters.nvim
===============================================================================================
Description: Evidenzia delimitatori annidati (parentesi, graffe, quadre) con colori diversi.
             Utilizza Tree-sitter per riconoscere la struttura sintattica e migliorare la
             leggibilità del codice anche in linguaggi molto nidificati.
Status: Active
Author: HiPhish
Repository: https://github.com/HiPhish/rainbow-delimiters.nvim
Notes:
 - Utilizza la strategia `global` per applicare l’highlight su tutto il buffer in una volta
 - Usa la query `rainbow-parens` di default per tutti i linguaggi, focalizzandosi solo su parentesi tonde, graffe e quadre per performance ottimali
 - I gruppi di highlight usati sono quelli standard del plugin:
 - Filetype esclusi vengono presi dinamicamente da `sphynx.config.excluded_filetypes`
TODO:
 - [ ] Aggiungere override per linguaggi come Lua o LaTeX con `rainbow-blocks`
 - [ ] Introdurre priorità custom con il campo `priority` per una gestione più robusta
===============================================================================================
--]]

local M = {}

M.plugins = {
    ["rainbow-delimiters"] = {
        "HiPhish/rainbow-delimiters.nvim",
        event = { "BufReadPost", "BufNewFile" }, -- allineato a indent-blankline (suo dependent): evita che ibl referenzi gruppi RainbowDelimiter* non ancora definiti
    },
}

M.configs = {
    ["rainbow-delimiters"] = function()
        require("rainbow-delimiters.setup").setup({
            strategy = {
                [""] = "rainbow-delimiters.strategy.global",
            },
            query = {
                [""] = "rainbow-delimiters",
                lua = "rainbow-blocks",
            },
            highlight = {
                "RainbowDelimiterRed",
                "RainbowDelimiterYellow",
                "RainbowDelimiterBlue",
                "RainbowDelimiterOrange",
                "RainbowDelimiterGreen",
                "RainbowDelimiterViolet",
                "RainbowDelimiterCyan",
            },
            blacklist = sphynx.config.excluded_filetypes,
        })
    end,
}

return M
