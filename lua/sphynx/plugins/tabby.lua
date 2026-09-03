--[[
===============================================================================================
Plugin: tabby.nvim
===============================================================================================
Description: Tabline dichiarativa e altamente configurabile. Qui e' usata in modalita'
             "bufferline" (mostra l'elenco dei buffer aperti a sinistra) con la sezione
             dei tab vim nativi a destra, piu' un logo e un padding allineato a NvimTree.
Status: Active
Author: nanozuki
Repository: https://github.com/nanozuki/tabby.nvim
Notes:
 - Caricamento lazy su VeryLazy (tabby non e' lento; con VeryLazy la tabline grezza viene
   renderizzata prima e poi ridisegnata da tabby)
 - showtabline = 2: la tabline e' sempre visibile, anche con un solo tab
 - buf_name mode = "unique": nome buffer minimo ma univoco; fallback "[No Name]"
 - tab_name fallback: nome della cartella del primo buffer del tab (project name)
 - Tema costruito da sphynx.colors e riapplicato sull'evento ColorScheme (augroup dedicato)
 - Padding dinamico a sinistra allineato alla larghezza di NvimTree quando e' aperto
 - Filtro buffer: esclusi per filetype NvimTree, neo-tree, TelescopePrompt, qf, help
 - Indicatore di modifica del buffer con il glifo "●"; in jump mode il tab mostra "[key]"
 - sessionoptions += tabpages, globals: salva/ripristina layout e nomi dei tab nelle sessioni
 - Comandi utente definiti qui: BufOnly (chiude tutti i buffer tranne il corrente),
   Bd (chiude il buffer corrente senza chiudere la finestra)
Keymaps (prefisso <leader>w = workspace):
 - <leader>wr        → Rinomina il tab corrente (vim.ui.input → Tabby rename_tab)
 - <leader>wn        → Nuovo tab
 - <leader>wj        → Jump mode: salta a un tab con un tasto (Tabby jump_to_tab)
 - <leader>ww        → Pick window tra i tab (Tabby pick_window)
 - <leader>w<Left>   → Tab precedente
 - <leader>w<Right>  → Tab successivo
 - <leader>wm<Left>  → Sposta il tab a sinistra
 - <leader>wm<Right> → Sposta il tab a destra
 - <leader>wcc       → Chiude il tab corrente e i suoi buffer (solo tab corrente)
 - <leader>wc1..wc0  → Chiude il tab N (hidden, generati in loop)
===============================================================================================
--]]

local M = {}

M.plugins = {
    ["tabby"] = {
        "nanozuki/tabby.nvim",
        lazy = true,
        event = "VeryLazy",
    },
}

M.setup = {
    ["tabby"] = function()
        M.keybindings()
    end,
}

-- Funzione separata per configurare il tema di Tabby (richiamabile su ColorScheme)
local function setup_tabby_theme()
    local colors = require("sphynx.colors").get_color()

    local theme = {
        fill = { bg = colors.grey13 },
        TabLineLogo = { fg = colors.cyan, bg = colors.grey13 },
        TabLineaPadding = { bg = colors.grey13 },
        TabLineWinCur = { fg = colors.blue, bg = colors.bg1 },
        TabLineWinSepCur = { fg = colors.blue, bg = colors.bg1 },
        TabLineWin = { fg = colors.grey4, bg = colors.grey13 },
        TabLineWinSep = { fg = colors.grey10, bg = colors.grey13 },
        TabLineBufCurModified = { fg = colors.yellow, bg = colors.bg1 },
        TabLineBufModified = { fg = colors.yellow, bg = colors.grey13 },
        head = "TabLine",
        current_tab = { fg = colors.bg, bg = colors.blue, style = "bold" },
        tab = { fg = colors.grey4, bg = colors.grey9 },
        current_buf = "TabLineSel",
        buf = { fg = colors.grey8, bg = colors.grey12 },
        separator = { fg = colors.grey8, bg = colors.grey12 },
        TabLineTab = { fg = colors.grey9, bg = colors.bg },
        TabLineTabCur = { fg = colors.bg, bg = colors.grey9 },
        TabLineTabSepCur = { fg = colors.grey9, bg = colors.bg },
    }

    local function createLogo(line)
        return {
            { "  ", hl = theme.TabLineLogo },
            { "", hl = theme.TabLineLogo },
        }
    end

    local function get_nvimtree_padding()
        local api = vim.api
        local current_tab = api.nvim_get_current_tabpage()
        local wins = api.nvim_tabpage_list_wins(current_tab)
        local logo_width = 3 -- 1 spazio + icona + 1 spazio

        local nvimtree_width = 0

        for _, win in ipairs(wins) do
            local buf = api.nvim_win_get_buf(win)
            local ft = api.nvim_get_option_value("filetype", { buf = buf })

            -- finestra NvimTree: usiamo la sua larghezza come padding
            if ft == "NvimTree" then
                nvimtree_width = api.nvim_win_get_width(win) - logo_width
                if nvimtree_width < 0 then
                    nvimtree_width = 0
                end
            end
        end

        return nvimtree_width
    end

    local function filterBuffers(buf)
        local excluded = { "NvimTree", "neo-tree", "TelescopePrompt", "qf", "help" }
        local ft = vim.api.nvim_get_option_value("filetype", { buf = buf.id })
        return not vim.tbl_contains(excluded, ft)
    end

    -- Funzione per renderizzare un singolo buffer
    local function renderBuffer(buf, i, count, line)
        local hl, pre
        local preSym = "▌"
        local preSym_cur = "▏"

        if buf.is_current() then
            hl = theme.TabLineWinCur
            pre = { preSym .. " ", hl = theme.TabLineWinSepCur }
        else
            hl = theme.TabLineWin
            pre = { preSym_cur .. " ", hl = theme.TabLineWinSep }
        end

        local icon = buf.file_icon()
        if icon then
            icon = icon .. " "
        else
            icon = ""
        end

        return {
            pre,
            icon,
            buf.name(),
            {
                buf.is_changed() and "● " or "  ",
                hl = buf.is_current() and theme.TabLineBufCurModified or theme.TabLineBufModified,
            },
            hl = hl,
        }
    end

    local function renderTab(tab, i, count)
        local hl = tab.is_current() and theme.current_tab or theme.tab

        -- Indicatore visuale diverso per stati diversi
        local prefix = ""
        if tab.in_jump_mode() then
            prefix = "[" .. tab.jump_key() .. "] " -- [a] in jump mode
        else
            prefix = "" -- spazio per allineamento
        end

        return {
            prefix,
            tab.name(),
            tab.close_btn("×"),
            i < count and "  " or "",
            hl = hl,
            margin = " ",
        }
    end

    -- Componente tail per i tab
    local function createTabSection(line)
        return {
            line.sep("", theme.head, theme.fill),
            { "  ", hl = theme.head },
        }
    end

    require("tabby").setup({
        option = {
            buf_name = {
                mode = "unique",
                name_fallback = function(bufid)
                    return "[No Name]"
                end,
            },
            tab_name = {
                name_fallback = function(tabid)
                    -- Nome intelligente basato sul contenuto del tab
                    local wins = vim.api.nvim_tabpage_list_wins(tabid)
                    if #wins > 0 then
                        local bufid = vim.api.nvim_win_get_buf(wins[1])
                        local path = vim.api.nvim_buf_get_name(bufid)
                        if path ~= "" then
                            local project = vim.fn.fnamemodify(path, ":p:h:t")
                            return project ~= "" and project or "Tab"
                        end
                    end
                    return "Tab"
                end,
            },
        },
        line = function(line)
            local tab_count = vim.fn.tabpagenr("$")
            local show_tabs = tab_count > 1

            -- calcola padding dinamico in base a NvimTree
            local nvimtree_padding = get_nvimtree_padding()
            local padding_node = ""

            if nvimtree_padding > 0 then
                padding_node = { string.rep(" ", nvimtree_padding), hl = theme.TabLineaPadding }
            end

            return {
                -- Header/Logo
                createLogo(line),

                -- Padding a sinistra quando NvimTree è aperto
                padding_node,

                -- Buffer section con filtro
                line.bufs().filter(filterBuffers).foreach(renderBuffer),

                -- Spacer centrale
                line.spacer(),

                -- Tab section
                show_tabs and line.tabs().foreach(renderTab) or "",

                -- Tail
                show_tabs and createTabSection(line) or "",

                -- Background generale
                hl = theme.fill,
            }
        end,
    })
end

M.configs = {
    ["tabby"] = function()
        vim.o.showtabline = 2

        -- Setup iniziale del tema
        setup_tabby_theme()

        -- Crea augroup per evitare autocmd duplicati
        local augroup = vim.api.nvim_create_augroup("TabbyColorScheme", { clear = true })

        -- Riconfigura Tabby quando cambia colorscheme
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = augroup,
            pattern = "*",
            callback = function()
                vim.schedule(function()
                    setup_tabby_theme()
                end)
            end,
        })

        -- Settings
        vim.opt.sessionoptions:append({ "tabpages", "globals" })

        -- Chiudi tutti i buffer tranne il corrente (solo file, non NvimTree)
        vim.api.nvim_create_user_command("BufOnly", function()
            local current = vim.api.nvim_get_current_buf()
            local to_close = vim.tbl_filter(function(b)
                if b == current then
                    return false
                end
                if not vim.fn.buflisted(b) then
                    return false
                end
                local bt = vim.bo[b].buftype
                if bt ~= "" then
                    return false
                end
                local name = vim.api.nvim_buf_get_name(b)
                if name:match("^NvimTree_%d+$") then
                    return false
                end
                return true
            end, vim.api.nvim_list_bufs())
            for _, buf in ipairs(to_close) do
                pcall(vim.api.nvim_buf_delete, buf, { force = false })
            end
        end, {})

        -- Chiudi buffer senza chiudere finestra
        vim.api.nvim_create_user_command("Bd", function()
            local current = vim.api.nvim_get_current_buf()

            -- Trova un buffer valido a cui passare prima di cancellare
            local next_buf = nil
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                if b ~= current
                    and vim.api.nvim_buf_is_valid(b)
                    and vim.bo[b].buftype == ""
                    and vim.fn.buflisted(b)
                    and not vim.api.nvim_buf_get_name(b):match("^NvimTree_%d+$") then
                    next_buf = b
                    break
                end
            end

            if next_buf then
                pcall(vim.api.nvim_set_current_buf, next_buf)
            end

            pcall(vim.api.nvim_buf_delete, current, { force = false })
        end, {})
    end,
}

M.keybindings = function()
    local mapping = require("sphynx.core.5-mapping")
    local wk = require("which-key")
    local prefix = "w"

    local function rename_tab()
        vim.ui.input({ prompt = "Nome tab: " }, function(name)
            if name and name ~= "" then
                vim.cmd("Tabby rename_tab " .. name)
            end
        end)
    end

    wk.add({
        { "<leader>" .. prefix, group = "  Workspace" },
        { "<leader>" .. prefix .. "r", rename_tab, desc = "Rinomina tab [Tabby]" },
        { "<leader>" .. prefix .. "n", [[<Cmd>tabnew<CR>]], desc = "Tab new [Tabby]" },
        { "<leader>" .. prefix .. "j", [[<Cmd>Tabby jump_to_tab<CR>]], desc = "Jump to Tab [Tabby]" },
        { "<leader>" .. prefix .. "w", [[<Cmd>Tabby pick_window<CR>]], desc = "Pick window tab [Tabby]" },
        { "<leader>" .. prefix .. "<Left>", [[<Cmd>tabprevious<CR>]], desc = "Tab left [Tabby]" },
        { "<leader>" .. prefix .. "<Right>", [[<Cmd>tabnext<CR>]], desc = "Tab right [Tabby]" },
        { "<leader>" .. prefix .. "c", group = " Close [Tabby]" },
        {
            "<leader>" .. prefix .. "c" .. "c",
            [[<Cmd>lua require('sphynx.utils').closeAllBufs('closeTab')<CR>]],
            desc = "Close current tab [utils=>init.lua]",
        },
        { "<leader>" .. prefix .. "c" .. "#", desc = "Close tab .N [Workspace]" },
        { "<leader>" .. prefix .. "m", group = "󰆾 Move" },
        { "<leader>" .. prefix .. "m" .. "<Left>", [[<Cmd>:-tabmove<CR>]], desc = "Move tab left [Tabby]" },
        { "<leader>" .. prefix .. "m" .. "<Right>", [[<Cmd>:+tabmove<CR>]], desc = "Move tab right [Tabby]" },
    }, mapping.opt_mappping)

    -- Close tab .N
    for i = 1, 10 do
        wk.add({
            {
                "<leader>" .. prefix .. "c" .. tostring(i),
                [[<Cmd>WS ]] .. tostring(i) .. [[ | lua require('sphynx.utils').closeAllBufs('closeTab')<CR>]],
                hidden = true,
            },
        }, mapping.opt_mappping)
    end
end

return M
