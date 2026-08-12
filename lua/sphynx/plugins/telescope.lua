--[[
===============================================================================================
Plugin: telescope.nvim
===============================================================================================
Description: Fuzzy finder estendibile: cerca, filtra, anteprima e seleziona file, buffer, tag,
             simboli LSP, grep, ecc. tramite picker su finestra flottante.
Status: Active
Author: nvim-telescope
Repository: https://github.com/nvim-telescope/telescope.nvim
Notes:
 - Caricamento lazy: si carica sui comandi "Telescope" e "SearchSession".
 - version = "*": si aggancia all'ultimo tag stabile (attuale: v0.2.2).
 - Dipendenze: plenary, nvim-web-devicons, trouble.nvim e telescope-fzf-native (build "make")
   come sorter nativo per performance; se manca, fallback con notify di avviso.
 - Tuning anteprima: filesize_limit = 10 MB e timeout = 1500 ms per evitare blocchi su file
   grandi/lenti; file_ignore_patterns esclude immagini, node_modules, doc/ sotto nvim-data
   e la cartella Neovim Doc.
 - Mappings <C-j>/<C-k> per muoversi, <C-v>/<C-s>/<C-t> per split/tab, <C-n> apre in Trouble,
   <C-q> manda alla quickfix, <Tab> multi-selezione.
 - no_preview(): tema dropdown con entry_maker stile LeaderF per il picker buffers (bb).
Keymaps:
 - bb              → switch buffer (dropdown senza preview)
 - tS              → tags stack
 - <leader>tf      → find files (git_files in repo, find_files altrove)
 - <leader>tg      → live grep            - <leader>tw → grep parola (prompt)
 - <leader>ts      → fuzzy nel buffer     - <leader>tq → nodi treesitter
 - <leader>to      → old files            - <leader>ty → neoclip (yank ring)
 - <leader>tk/th/te/tv/ta/tc → keymaps/help/commands/vim options/autocmd/highlights
 - <leader>tT      → tutti i picker       - <leader>tn → moduli config neovim
 - <leader>tl{r,a,i,d,b,s} → LSP references/code action/implementations/definitions/
                             document symbols/workspace symbols
===============================================================================================
--]]

local M = {}

M.plugins = {
    ["telescope"] = {
        "nvim-telescope/telescope.nvim",
        version = "*",
        lazy = true,
        cmd = { "Telescope", "SearchSession" },
        -- wants = {
        --     "plenary.nvim",
        --     "nvim-web-devicons",
        --     "trouble.nvim",
        --     "telescope-fzf-native.nvim",
        -- },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "kyazdani42/nvim-web-devicons",
            "folke/trouble.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
    },
}

M.setup = {
    ["telescope"] = function()
        M.keybindings()
    end,
}

M.no_preview = function()
    local function gen_from_buffer_like_leaderf(opts)
        opts = opts or {}
        local devicons = require("nvim-web-devicons")
        local default_icons, _ = devicons.get_icon("file", "", { default = true })
        local filter = vim.tbl_filter
        local entry_display = require("telescope.pickers.entry_display")
        local map = vim.tbl_map

        local bufnrs = filter(function(b)
            return 1 == vim.fn.buflisted(b)
        end, vim.api.nvim_list_bufs())

        local max_bufnr = math.max(1, unpack(bufnrs))
        local bufnr_width = #tostring(max_bufnr)

        local max_bufname = math.max(
            1,
            unpack(map(function(bufnr)
                return vim.fn.strdisplaywidth(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p:t"))
            end, bufnrs))
        )

        local displayer = entry_display.create({
            separator = " ",
            items = {
                { width = bufnr_width },
                { width = 4 },
                { width = vim.fn.strwidth(default_icons) },
                { width = max_bufname },
                { remaining = true },
            },
        })

        local make_display = function(entry)
            return displayer({
                { entry.bufnr, "TelescopeResultsNumber" },
                { entry.indicator, "TelescopeResultsComment" },
                { entry.devicons, entry.devicons_highlight },
                entry.file_name,
                { entry.dir_name, "Comment" },
            })
        end

        return function(entry)
            local bufname = entry.info.name ~= "" and entry.info.name or "[No Name]"
            local hidden = entry.info.hidden == 1 and "h" or "a"
            local readonly = vim.api.nvim_get_option_value("readonly", { buf = entry.bufnr }) and "=" or " "
            local changed = entry.info.changed == 1 and "+" or " "
            local indicator = entry.flag .. hidden .. readonly .. changed

            local dir_name = vim.fn.fnamemodify(bufname, ":p:h")
            local file_name = vim.fn.fnamemodify(bufname, ":p:t")

            local icons, highlight = devicons.get_icon(bufname, string.match(bufname, "%a+$"), { default = true })

            return {
                valid = true,

                value = bufname,
                ordinal = entry.bufnr .. " : " .. file_name,
                display = make_display,

                bufnr = entry.bufnr,

                lnum = entry.info.lnum ~= 0 and entry.info.lnum or 1,
                indicator = indicator,
                devicons = icons,
                devicons_highlight = highlight,

                file_name = file_name,
                dir_name = dir_name,
            }
        end
    end

    return require("telescope.themes").get_dropdown({
        -- borderchars = {
        --   { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        --   prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
        --   results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
        --   preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        -- },
        layout_config = {
            prompt_position = "top",
            width = 0.4,
        },
        previewer = false,
        entry_maker = gen_from_buffer_like_leaderf(),
    })
end

M.builtins = function()
    require("telescope.builtin").builtin(M.no_preview())
end

M.grep_prompt = function()
    require("telescope.builtin").grep_string({
        path_display = { "shorten" },
        search = vim.fn.input("Grep String > "),
        only_sort_text = true,
        use_regex = true,
    })
end

M.workspace_symbols = function()
    require("telescope.builtin").lsp_workspace_symbols({
        path_display = { "truncate" },
        layout_config = {
            prompt_position = "bottom",
            horizontal = {
                mirror = false,
                width = 0.95,
                height = 0.87,
                preview_width = 0.5,
            },
        },
    })
end

M.project_files = function()
    local opts = {} -- define here if you want to define something
    vim.fn.system("git rev-parse --is-inside-work-tree")
    if vim.v.shell_error == 0 then
        require("telescope.builtin").git_files(opts)
    else
        require("telescope.builtin").find_files(opts)
    end
end

M.neovim_module = function()
    -- Telescope will give us something like ju/colors.lua,
    -- so this function convert the selected entry to
    -- the module name: ju.colors
    local function get_module_name(s)
        local module_name

        module_name = s:gsub("%.lua", "")
        module_name = module_name:gsub("%/", ".")
        module_name = module_name:gsub("%.init", "")

        return module_name
    end

    local prompt_title = "~ neovim modules ~"

    -- sets the path to the lua folder
    -- local path = vim.env.HOME .. '/nvim/develoment/lua/'
    local path = sphynx.path.plugin_config_folder
    local ignore_patterns = {
        "vimfiles\\lsp",
        "plugged",
        "view_nvim",
        "session_nvim",
        "session",
        "undo",
        "undo_nvim",
        ".git/",
        "node_modules",
    }

    local opts = {
        prompt_title = prompt_title,
        cwd = path,
        file_ignore_patterns = ignore_patterns,

        attach_mappings = function(_, map)
            -- Adds a new map to ctrl+e.
            map("i", "<c-e>", function(_)
                -- these two a very self-explanatory
                local entry = require("telescope.actions.state").get_selected_entry()
                local name = get_module_name(entry.value)

                -- call the helper method to reload the module
                -- and give some feedback
                -- R(name)
                P(name .. " RELOADED!!!")
            end)

            return true
        end,
    }

    -- call the builtin method to list files
    require("telescope.builtin").find_files(opts)
end

M.configs = {
    ["telescope"] = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local previewers = require("telescope.previewers")
        local open_with_trouble = require("trouble.sources.telescope").open

        telescope.setup({
            defaults = {
                prompt_prefix = " ",
                selection_caret = "> ",
                entry_prefix = "  ",
                dynamic_preview_title = true, -- titolo preview dinamico (tipo contenuto + n. righe), usato da neoclip
                file_previewer = previewers.vim_buffer_cat.new,
                grep_previewer = previewers.vim_buffer_vimgrep.new,
                qflist_previewer = previewers.vim_buffer_qflist.new,
                buffer_previewer_maker = previewers.buffer_previewer_maker,
                preview = {
                    filesize_limit = 10,
                    timeout = 1500,
                },
                file_ignore_patterns = {
                    "%.png",
                    "%.jpg",
                    "%.webp",
                    "node_modules",
                    "node_modules_custom",
                    "[/\\]nvim%-data[/\\].-[/\\]doc[/\\]", -- doc/ sotto nvim-data (help dei plugin)
                    "Neovim Doc[/\\]", -- cartella di documentazione/appunti personali
                },
                scroll_strategy = "cycle",
                selection_strategy = "reset",
                layout_strategy = "horizontal",
                border = true,
                borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
                -- vimgrep_arguments = {
                --     "ugrep",
                --     '--dereference-recursive',
                --     '--ignore-binary',
                --     '--line-number',
                --     '--column-number',
                --     '--smart-case',
                --     '--ungroup',
                --     '--context=0',
                --     '--ignore-files',
                --     '--color=never',
                -- },
                layout_config = {
                    prompt_position = "bottom",
                    width = 0.85,
                    preview_cutoff = 120,
                    horizontal = {
                        mirror = false,
                        width = 0.8,
                        height = 0.8,
                        preview_width = 0.6,
                    },
                    vertical = {
                        mirror = false,
                    },
                },
                mappings = {
                    i = {
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,

                        ["<C-v>"] = actions.select_vertical,
                        ["<C-s>"] = actions.select_horizontal,
                        ["<C-t>"] = actions.select_tab,

                        ["<C-c>"] = actions.close,
                        -- ["<Esc>"] = actions.close,

                        ["<PageUp>"] = actions.preview_scrolling_up,
                        ["<PageDown>"] = actions.preview_scrolling_down,
                        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
                        ["<C-n>"] = open_with_trouble,
                        ["<Tab>"] = actions.toggle_selection,
                        -- ["<C-r>"] = actions.refine_result,
                    },
                    n = {
                        ["<CR>"] = actions.select_default + actions.center,
                        ["<C-v>"] = actions.select_vertical,
                        ["<C-x>"] = actions.select_horizontal,
                        ["<C-t>"] = actions.select_tab,
                        ["<Esc>"] = actions.close,

                        ["j"] = actions.move_selection_next,
                        ["k"] = actions.move_selection_previous,

                        ["<PageUp>"] = actions.preview_scrolling_up,
                        ["<PageDown>"] = actions.preview_scrolling_down,
                        ["<C-q>"] = actions.send_to_qflist,
                        ["<C-n>"] = open_with_trouble,
                        ["<Tab>"] = actions.toggle_selection,
                    },
                },
            },
            pickers = {
                -- live_grep = {
                --     on_input_filter_cb = function(prompt)
                --         -- AND operator for live_grep like how fzf handles spaces with wildcards in rg
                --         return { prompt = prompt:gsub("%s", ".*") }
                --     end,
                -- },
            },
            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                },
            },
        })

        -- superfast sorter
        local fzf_status_ok, _ = pcall(require, "fzf_lib")
        if fzf_status_ok then
            telescope.load_extension("fzf")
        else
            vim.notify(
                "Installare telescope-fzf-native.nvim per migliori perfomance",
                vim.log.levels.WARN,
                { title = "Telescope", icon = " ", timeout = 5000 }
            )
        end
    end,
}

M.keybindings = function()
    local mapping = require("sphynx.core.5-mapping")
    local wk = require("which-key")
    local prefix = "t"

    -- require("which-key").add({
    -- ["b"] = {
    -- name = " Buff
    -- ers",
    -- ["b"] = {[[<Cmd>lua require('telescope.builtin').buffers(require('sphynx.plugins.telescope').no_preview())<CR>]], "Switch buffer [Telescope]"},
    -- }
    -- }, mapping.opt_mappping)

    wk.add({
        {
            "bb",
            [[<Cmd>lua require('telescope.builtin').buffers(require('sphynx.plugins.telescope').no_preview())<CR>]],
            desc = "Switch buffer [Telescope]",
        },
    }, mapping.opt_mappping)

    wk.add({
        { "tS", [[<CMD>Telescope tagstack<CR>]], desc = "Tags stack [Telescope]" },
    })

    wk.add({
        { "<leader>" .. prefix, group = " Telescope" },
        {
            "<leader>" .. prefix .. "f",
            [[<Cmd>lua require("sphynx.plugins.telescope").project_files()<CR>]],
            desc = "find files",
        },
        {
            "<leader>" .. prefix .. "s",
            [[<Cmd>lua require('telescope.builtin').current_buffer_fuzzy_find()<CR>]],
            desc = "search in current buffer",
        },
        {
            "<leader>" .. prefix .. "q",
            [[<Cmd>lua require('telescope.builtin').treesitter()<CR>]],
            desc = "find treesitter node",
        },
        { "<leader>" .. prefix .. "t", [[<Cmd>lua require('telescope.builtin').tags()<CR>]], desc = "find tags" },
        { "<leader>" .. prefix .. "S", [[<Cmd>lua require('telescope.builtin').tagstack()<CR>]], desc = "tags stack" },
        { "<leader>" .. prefix .. "g", [[<Cmd>lua require('telescope.builtin').live_grep()<CR>]], desc = "grep" },
        { "<leader>" .. prefix .. "o", [[<Cmd>lua require('telescope.builtin').oldfiles()<CR>]], desc = "old file" },
        {
            "<leader>" .. prefix .. "c",
            [[<Cmd>lua require('telescope.builtin').highlights()<CR>]],
            desc = "highlights",
        },
        { "<leader>" .. prefix .. "k", [[<Cmd>lua require('telescope.builtin').keymaps()<CR>]], desc = "keymaps" },
        { "<leader>" .. prefix .. "h", [[<Cmd>lua require('telescope.builtin').help_tags()<CR>]], desc = "help" },
        { "<leader>" .. prefix .. "e", [[<Cmd>lua require('telescope.builtin').commands()<CR>]], desc = "commands" },
        {
            "<leader>" .. prefix .. "v",
            [[<Cmd>lua require('telescope.builtin').vim_options()<CR>]],
            desc = "vim option",
        },
        { "<leader>" .. prefix .. "a", [[<Cmd>lua require('telescope.builtin').autocommands()<CR>]], desc = "autocmd" },
        {
            "<leader>" .. prefix .. "y",
            [[<Cmd>lua require('telescope').extensions.neoclip.neoclip(require('telescope.themes').get_dropdown({ winblend = 10, layout_config={width=0.7 }, initial_mode="normal" }))<CR>]],
            desc = "neoclip",
        },
        {
            "<leader>" .. prefix .. "T",
            [[<Cmd>lua require("sphynx.plugins.telescope").builtins()<CR>]],
            desc = "Serch all Telescope",
        },
        {
            "<leader>" .. prefix .. "n",
            [[<Cmd>lua require('sphynx.plugins.telescope').neovim_module()<CR>]],
            desc = "neovim module config",
        },
        {
            "<leader>" .. prefix .. "w",
            [[<Cmd>lua require("sphynx.plugins.telescope").grep_prompt({})<CR>]],
            desc = "grep word",
        },

        -- LSP submenu
        { "<leader>" .. prefix .. "l", group = "+lsp" },
        {
            "<leader>" .. prefix .. "lr",
            [[<Cmd>lua require('telescope.builtin').lsp_references()<CR>]],
            desc = "reference",
        },
        {
            "<leader>" .. prefix .. "la",
            [[<Cmd>lua vim.lsp.buf.code_action()<CR>]],
            desc = "code actions",
        },
        {
            "<leader>" .. prefix .. "li",
            [[<Cmd>lua require('telescope.builtin').lsp_implementations()<CR>]],
            desc = "implementations",
        },
        {
            "<leader>" .. prefix .. "ld",
            [[<Cmd>lua require('telescope.builtin').lsp_definitions()<CR>]],
            desc = "definitions",
        },
        {
            "<leader>" .. prefix .. "lb",
            [[<Cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]],
            desc = "buffer symbols",
        },
        {
            "<leader>" .. prefix .. "ls",
            [[<Cmd>lua require("sphynx.plugins.telescope").workspace_symbols()<CR>]],
            desc = "workspace symbols",
        },
    }, mapping.opt_mappping)
end

return M
