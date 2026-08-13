-- NOTE: PLUGIN: nvim-window-picker
-- DESCRIZIONE:
-- Mi permette di passage da una finestra all'altra in modo molto rapido
-- MAPPING:
-- <w-w> => si attiva e mostra la lettera della finestra su cui mi voglio spostare
-- <w-s> => mi permette di spostare due finestre facendo lo switch tra di loro
-- OSSERVAZIONI:
-- Questo plugin si integra anche con nvim-tree quando apro un file mi mostra una lettera sulle varie finestre
-- e il file si aprirà nella finestra corrsipondente alla lettera selezionata

local M = {}

M.plugins = {
    ["nvim-window-picker"] = {
        "s1n7ax/nvim-window-picker",
        lazy = true,
        event = "VeryLazy",
        version = "2.*",
    },
}

M.setup = {
    ["nvim-window-picker"] = function()
        M.keybindings()
    end,
}

M.configs = {
    ["nvim-window-picker"] = function()
        local picker = require("window-picker")
        picker.setup({
            autoselect_one = true,
            hint = "floating-big-letter",
            include_current = false,
            -- whether to show 'Pick window:' prompt
            show_prompt = false,
            selection_chars = "ABCDEFGHIJKLMNOP",
            filter_rules = {
                include_current_win = false,
                autoselect_one = true,
                -- filter using buffer options
                bo = {
                    -- if the file type is one of following, the window will be ignored
                    filetype = { "NvimTree", "neo-tree", "neo-tree-popup", "notify", "snacks_notif" },
                    -- if the buffer type is one of following, the window will be ignored
                    buftype = { "terminal", "quickfix", "nofile" },
                },
            },
            statusline_winbar_picker = {
                -- You can change the display string in status bar.
                -- It supports '%' printf style. Such as `return char .. ': %f'` to display
                -- buffer file path. See :h 'stl' for details.
                selection_display = function(char, _)
                    return "%=" .. char .. "%="
                end,
                floating_big_letter = {
                    -- window picker plugin provides bunch of big letter fonts
                    -- fonts will be lazy loaded as they are being requested
                    -- additionally, user can pass in a table of fonts in to font
                    -- property to use instead
                    font = "ansi-shadow", -- ansi-shadow |
                },

                -- whether you want to use winbar instead of the statusline
                -- "always" means to always use winbar,
                -- "never" means to never use winbar
                -- "smart" means to use winbar if cmdheight=0 and statusline if cmdheight > 0
                use_winbar = "never", -- "always" | "never" | "smart"
            },
            highlights = {
                statusline = {
                    focused = {
                        fg = "#ededed",
                        bg = "#3C424C",
                        bold = true,
                    },
                    unfocused = {
                        fg = "#ededed",
                        bg = "#757A84",
                        bold = true,
                    },
                },
                winbar = {
                    focused = {
                        fg = "#ededed",
                        bg = "#81b29a",
                        bold = true,
                    },
                    unfocused = {
                        fg = "#ededed",
                        bg = "#3C424C",
                        bold = true,
                    },
                },
            },
        })
    end,
}

M.keybindings = function()
    local mapping = require("sphynx.core.5-mapping")
    local picker = require("window-picker")

    -- Swap two windows using picker
    local function swap_windows()
        local window = picker.pick_window({
            include_current_win = false,
        })
        local target_buffer = vim.fn.winbufnr(window)
        -- Set the target window to contain current buffer
        vim.api.nvim_win_set_buf(window, 0)
        -- Set current window to contain target buffer
        vim.api.nvim_win_set_buf(0, target_buffer)
    end

    -- Go to window using picker
    local function picked_window()
        local picked_window_id = picker.pick_window({
            include_current_win = true,
        }) or vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(picked_window_id)
    end

    require("which-key").add({
        { "ws", swap_windows, desc = "Switch window [nvim-window-picker]" },
        { "ww", picked_window, desc = "Go to window [nvim-window-picker]" },
    })
end

return M
