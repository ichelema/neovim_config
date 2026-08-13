--[[
===============================================================================================
Plugin: nvim-tree.lua
===============================================================================================
Description: File explorer (sidebar) per Neovim. Mostra l'albero dei file del progetto,
             con stato git nel gutter, filtri, bookmark e gestione filesystem
             (crea/rinomina/sposta/elimina) direttamente dall'albero.
Status: Active
Author: kyazdani42 / nvim-tree
Repository: https://github.com/nvim-tree/nvim-tree.lua
Notes:
 - Caricamento lazy via "cmd": si carica al primo NvimTreeOpen/Toggle/FindFile
 - netrw disabilitato (disable_netrw = true) per non avere conflitti
 - Stato git abilitato; git.timeout alzato a 5000ms perche' su Windows "git status"
   in questo repo impiega ~2.4s e il default (400ms) andava sempre in timeout
 - update_focused_file.enable = false: l'albero NON segue automaticamente il file attivo
 - Filtri custom (project_custom_filter): nasconde sempre .git, node_modules, .cargo, .cache
   e in piu' gli elementi elencati in "hide" del .nvim-tree.toml (per nome o per path)
 - Config progetto unificata: crea .nvim-tree.toml nella root del progetto
   Campi supportati:
     sort = "manual" | "name" | "created-desc" | "created-asc" | "modified-desc" | "modified-asc"
     fallback_sort = "name" | "created-desc" | "created-asc" | "modified-desc" | "modified-asc"
     order = ["README.md", "src", "src/main.lua"]
     hide = ["dist", "coverage", "frontend/.next"]
   Comportamento (project_tree_sorter):
     - senza file di config: ordine "name" (cartelle prima, poi alfabetico)
     - "order" impone un ordine manuale agli elementi elencati; il resto segue fallback_sort
     - "created" usa la data di creazione (birthtime) con fallback su mtime quando assente
     - il .nvim-tree.toml e' ri-letto solo se cambia (cache su mtime); valori non validi → warning
 - Aggiornamento albero: usa "R" sull'albero (api.tree.reload) per il refresh manuale
 - "C" = cambia root (CD), "G" = toggle git-clean filter (mostra solo i file modificati)

Dipendenze / plugin correlati:
 - nvim-tree-preview.lua : anteprima del file senza aprirlo
     <Tab> sul file  → apre/chiude l'anteprima (toggle focus tra albero e preview)
     <Tab> su cartella → espande la cartella
     P               → preview "watch" (segue il cursore nell'albero)
     <Esc>           → chiude l'anteprima
     dentro la preview: <CR> edit, <C-v> vsplit, <C-x> split, <C-t> tab
 - nvim-window-picker : sceglie in quale finestra aprire il file (vedi config dedicata)

Keymaps (globali):
 - <F4>  → NvimTreeToggle    (apre/chiude l'explorer)
 - <F3>  → NvimTreeFindFile  (trova il file corrente nell'albero)
 - <F2>  → NvimTreeFocus     (sposta il focus sull'explorer)
TODO:
 - [ ] Valutare update_focused_file.enable = true per seguire il file attivo
 - [ ] Le keymap A/E, ?/g?, s/Z sono alias volontari (stessa azione, tasti diversi)
===============================================================================================
--]]

local M = {}

M.plugins = {
    ["nvim-tree.lua"] = {
        "kyazdani42/nvim-tree.lua",
        cmd = { "NvimTreeOpen", "NvimTreeToggle", "NvimTreeFindFile" },
        dependencies = {
            "b0o/nvim-tree-preview.lua",
        },
    },
}

M.setup = {
    ["nvim-tree.lua"] = function()
        M.keybindings()
    end,
}

M.configs = {
    ["nvim-tree.lua"] = function()
        local project_config_file = ".nvim-tree.toml"

        local sort_mode_aliases = {
            manual = "manual",
            order = "manual",

            name = "name",
            alpha = "name",
            alphabetical = "name",

            created = "created-desc",
            creation = "created-desc",
            birthtime = "created-desc",
            newest = "created-desc",
            ["created-desc"] = "created-desc",
            ["creation-desc"] = "created-desc",
            ["birthtime-desc"] = "created-desc",

            oldest = "created-asc",
            ["created-asc"] = "created-asc",
            ["creation-asc"] = "created-asc",
            ["birthtime-asc"] = "created-asc",

            modified = "modified-desc",
            mtime = "modified-desc",
            ["modified-desc"] = "modified-desc",
            ["mtime-desc"] = "modified-desc",

            ["modified-asc"] = "modified-asc",
            ["mtime-asc"] = "modified-asc",
        }

        local function normalize_path(path)
            if vim.fs and vim.fs.normalize then
                return vim.fs.normalize(path)
            end

            return path:gsub("\\", "/")
        end

        local function relative_to_root(path, root)
            path = normalize_path(path)
            root = normalize_path(root):gsub("/+$", "")

            local prefix = root .. "/"
            if path:sub(1, #prefix) == prefix then
                return path:sub(#prefix + 1)
            end

            return path
        end

        local function default_tree_sort(a, b)
            if a.type ~= b.type then
                return a.type == "directory"
            end

            return a.name:lower() < b.name:lower()
        end

        local function time_to_seconds(time_table)
            if type(time_table) ~= "table" then
                return nil
            end

            return tonumber(time_table.sec) or tonumber(time_table.tv_sec)
        end

        local stat_cache = {}

        local function node_stat(path)
            path = normalize_path(path or "")

            if stat_cache[path] ~= nil then
                return stat_cache[path]
            end

            local uv = vim.uv or vim.loop
            local ok, stat = pcall(uv.fs_stat, path)

            if ok then
                stat_cache[path] = stat or false
            else
                stat_cache[path] = false
            end

            return stat_cache[path]
        end

        local function node_time(node, kind)
            local stat = node_stat(node.absolute_path or node.name)

            if not stat then
                return 0
            end

            if kind == "created" then
                -- birthtime e' la vera data di creazione quando il filesystem la espone.
                -- Su alcuni filesystem puo' mancare o valere 0: in quel caso usiamo mtime.
                local birthtime = time_to_seconds(stat.birthtime)
                if birthtime and birthtime > 0 then
                    return birthtime
                end
            end

            return time_to_seconds(stat.mtime) or 0
        end

        local function tree_sort_by_time(kind, descending)
            return function(a, b)
                if a.type ~= b.type then
                    return a.type == "directory"
                end

                local a_time = node_time(a, kind)
                local b_time = node_time(b, kind)

                if a_time ~= b_time then
                    if descending then
                        return a_time > b_time
                    end

                    return a_time < b_time
                end

                return a.name:lower() < b.name:lower()
            end
        end

        local function comparator_for_sort_mode(sort_mode)
            if sort_mode == "created-desc" then
                return tree_sort_by_time("created", true)
            end

            if sort_mode == "created-asc" then
                return tree_sort_by_time("created", false)
            end

            if sort_mode == "modified-desc" then
                return tree_sort_by_time("modified", true)
            end

            if sort_mode == "modified-asc" then
                return tree_sort_by_time("modified", false)
            end

            if sort_mode == "name" or not sort_mode then
                return default_tree_sort
            end

            return nil
        end

        local function strip_toml_comment(line)
            local in_single = false
            local in_double = false
            local escaped = false

            for i = 1, #line do
                local char = line:sub(i, i)

                if in_double then
                    if escaped then
                        escaped = false
                    elseif char == "\\" then
                        escaped = true
                    elseif char == '"' then
                        in_double = false
                    end
                elseif in_single then
                    if char == "'" then
                        in_single = false
                    end
                else
                    if char == '"' then
                        in_double = true
                    elseif char == "'" then
                        in_single = true
                    elseif char == "#" then
                        return line:sub(1, i - 1)
                    end
                end
            end

            return line
        end

        local function parse_toml_strings(value)
            local result = {}
            local i = 1

            while i <= #value do
                local char = value:sub(i, i)

                if char == '"' then
                    local j = i + 1
                    local escaped = false
                    local buffer = {}

                    while j <= #value do
                        local current = value:sub(j, j)

                        if escaped then
                            local replacements = {
                                n = "\n",
                                r = "\r",
                                t = "\t",
                                ['"'] = '"',
                                ["\\"] = "\\",
                            }
                            table.insert(buffer, replacements[current] or current)
                            escaped = false
                        elseif current == "\\" then
                            escaped = true
                        elseif current == '"' then
                            break
                        else
                            table.insert(buffer, current)
                        end

                        j = j + 1
                    end

                    table.insert(result, table.concat(buffer))
                    i = j + 1
                elseif char == "'" then
                    local j = i + 1

                    while j <= #value and value:sub(j, j) ~= "'" do
                        j = j + 1
                    end

                    table.insert(result, value:sub(i + 1, j - 1))
                    i = j + 1
                else
                    i = i + 1
                end
            end

            return result
        end

        local function parse_toml_scalar(value)
            value = vim.trim(value or "")

            if value == "true" then
                return true
            end

            if value == "false" then
                return false
            end

            local quoted = parse_toml_strings(value)
            if quoted[1] then
                return quoted[1]
            end

            local bare = value:match("^([%w_%-]+)$")
            return bare
        end

        local function parse_project_toml(lines)
            local parsed = {}
            local collecting_key = nil
            local collecting_parts = {}

            local function finish_array()
                parsed[collecting_key] = parse_toml_strings(table.concat(collecting_parts, "\n"))
                collecting_key = nil
                collecting_parts = {}
            end

            for _, raw_line in ipairs(lines) do
                local line = vim.trim(strip_toml_comment(raw_line or ""))

                if line ~= "" then
                    if collecting_key then
                        table.insert(collecting_parts, line)

                        if line:find("%]") then
                            finish_array()
                        end
                    elseif not line:match("^%[.+%]$") then
                        local key, value = line:match("^([%w_%-]+)%s*=%s*(.+)$")

                        if key and value then
                            key = key:gsub("-", "_")
                            value = vim.trim(value)

                            if value:sub(1, 1) == "[" then
                                collecting_key = key
                                collecting_parts = { value }

                                if value:find("%]") then
                                    finish_array()
                                end
                            else
                                parsed[key] = parse_toml_scalar(value)
                            end
                        end
                    end
                end
            end

            if collecting_key then
                finish_array()
            end

            return parsed
        end

        local function build_project_config(parsed)
            local config = {
                sort = nil,
                fallback_sort = nil,
                order_rank = nil,
                hidden_names = {},
                hidden_paths = {},
            }

            if type(parsed.sort) == "string" then
                local raw_sort = parsed.sort:lower()
                config.sort = sort_mode_aliases[raw_sort] or raw_sort
            end

            if type(parsed.fallback_sort) == "string" then
                local raw_fallback_sort = parsed.fallback_sort:lower()
                config.fallback_sort = sort_mode_aliases[raw_fallback_sort] or raw_fallback_sort

                -- Il fallback serve solo per gli elementi non ordinati manualmente.
                -- Evitiamo la ricorsione logica di fallback_sort = "manual".
                if config.fallback_sort == "manual" then
                    config.fallback_sort = "name"
                end
            end

            local order_entries = parsed.order or parsed.manual_order
            if type(order_entries) == "table" and #order_entries > 0 then
                config.order_rank = {}

                for _, entry in ipairs(order_entries) do
                    entry = normalize_path(vim.trim(tostring(entry or "")):gsub("^%./", ""))

                    if entry ~= "" and not config.order_rank[entry] then
                        config.order_rank[entry] = vim.tbl_count(config.order_rank) + 1
                    end
                end
            end

            local hide_entries = parsed.hide or parsed.hidden or parsed.ignore
            if type(hide_entries) == "table" then
                for _, entry in ipairs(hide_entries) do
                    entry = normalize_path(vim.trim(tostring(entry or "")):gsub("^%./", ""):gsub("/+$", ""))

                    if entry ~= "" then
                        if entry:find("/", 1, true) then
                            config.hidden_paths[entry] = true
                        else
                            config.hidden_names[entry] = true
                        end
                    end
                end
            end

            return config
        end

        local project_config_cache = {
            root = nil,
            mtime = nil,
            config = nil,
        }

        local function empty_project_config()
            return {
                sort = nil,
                fallback_sort = nil,
                order_rank = nil,
                hidden_names = {},
                hidden_paths = {},
            }
        end

        local function load_project_config(root)
            local config_path = root .. "/" .. project_config_file
            local mtime = vim.fn.getftime(config_path)

            if project_config_cache.root == root and project_config_cache.mtime == mtime then
                return project_config_cache.config
            end

            local config = empty_project_config()

            if mtime ~= -1 then
                local ok, lines = pcall(vim.fn.readfile, config_path)

                if ok then
                    config = build_project_config(parse_project_toml(lines))
                else
                    vim.notify(
                        "nvim-tree: impossibile leggere " .. config_path .. ", uso configurazione predefinita",
                        vim.log.levels.WARN
                    )
                end
            end

            project_config_cache.root = root
            project_config_cache.mtime = mtime
            project_config_cache.config = config

            return config
        end

        local function project_tree_sorter(nodes)
            stat_cache = {}

            local root = vim.fn.getcwd()
            local project_config = load_project_config(root)
            local sort_mode = project_config.sort
            local fallback_sort_mode = project_config.fallback_sort or "name"
            local rank = project_config.order_rank

            -- Se c'e' un ordine manuale ma non e' stato indicato sort, assumiamo manual.
            if not sort_mode and rank then
                sort_mode = "manual"
            end

            local fallback_comparator = comparator_for_sort_mode(fallback_sort_mode)

            if not fallback_comparator then
                vim.notify(
                    "nvim-tree: valore fallback_sort non valido in "
                        .. project_config_file
                        .. ": "
                        .. tostring(fallback_sort_mode)
                        .. ", uso name",
                    vim.log.levels.WARN
                )
                fallback_comparator = default_tree_sort
            end

            if sort_mode ~= "manual" then
                local comparator = comparator_for_sort_mode(sort_mode)

                if comparator then
                    table.sort(nodes, comparator)
                    return
                end

                if sort_mode then
                    vim.notify(
                        "nvim-tree: valore sort non valido in " .. project_config_file .. ": " .. sort_mode .. ", uso fallback_sort",
                        vim.log.levels.WARN
                    )
                end

                table.sort(nodes, fallback_comparator)
                return
            end

            if not rank then
                table.sort(nodes, fallback_comparator)
                return
            end

            table.sort(nodes, function(a, b)
                local a_relative_path = relative_to_root(a.absolute_path or a.name, root)
                local b_relative_path = relative_to_root(b.absolute_path or b.name, root)
                local a_rank = rank[a_relative_path] or rank[a.name] or math.huge
                local b_rank = rank[b_relative_path] or rank[b.name] or math.huge

                -- Gli elementi dichiarati in order vincono sempre.
                if a_rank ~= b_rank then
                    return a_rank < b_rank
                end

                -- Tutto cio' che non e' dichiarato in order usa fallback_sort.
                -- Esempio: root manuale, contenuto delle cartelle per created-desc.
                return fallback_comparator(a, b)
            end)
        end

        local global_hidden_names = {
            [".git"] = true,
            ["node_modules"] = true,
            [".cargo"] = true,
            [".cache"] = true,
        }

        local function project_custom_filter(absolute_path)
            local root = vim.fn.getcwd()
            local project_config = load_project_config(root)
            local path = normalize_path(absolute_path)
            local name = vim.fn.fnamemodify(path, ":t")

            if global_hidden_names[name] then
                return true
            end

            local relative_path = relative_to_root(path, root):gsub("/+$", "")

            return project_config.hidden_names[name] == true or project_config.hidden_paths[relative_path] == true
        end

        local function on_attach(bufnr)
            local api = require("nvim-tree.api")
            local preview = require("nvim-tree-preview")

            local function opts(desc)
                return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
            end

            -- Default mappings. Feel free to modify or remove as you wish.
            --
            -- BEGIN_DEFAULT_ON_ATTACH
            vim.keymap.set("n", "<C-]>", api.tree.change_root_to_node, opts("CD"))
            vim.keymap.set("n", "<C-e>", api.node.open.replace_tree_buffer, opts("Open: In Place"))
            vim.keymap.set("n", "<C-k>", api.node.show_info_popup, opts("Info"))
            vim.keymap.set("n", "<C-r>", api.fs.rename_sub, opts("Rename: Omit Filename"))
            vim.keymap.set("n", "<C-t>", api.node.open.tab, opts("Open: New Tab"))
            vim.keymap.set("n", "<C-v>", api.node.open.vertical, opts("Open: Vertical Split"))
            vim.keymap.set("n", "<C-x>", api.node.open.horizontal, opts("Open: Horizontal Split"))
            vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, opts("Close Directory"))
            vim.keymap.set("n", "<CR>", api.node.open.edit, opts("Open"))
            -- vim.keymap.set('n', '<Tab>', api.node.open.preview,                 opts('Open Preview'))
            vim.keymap.set("n", ">", api.node.navigate.sibling.next, opts("Next Sibling"))
            vim.keymap.set("n", "<", api.node.navigate.sibling.prev, opts("Previous Sibling"))
            vim.keymap.set("n", ".", api.node.run.cmd, opts("Run Command"))
            vim.keymap.set("n", "-", api.tree.change_root_to_parent, opts("Up"))
            vim.keymap.set("n", "a", api.fs.create, opts("Create"))
            vim.keymap.set("n", "bmv", api.marks.bulk.move, opts("Move Bookmarked"))
            vim.keymap.set("n", "B", api.filter.no_buffer.toggle, opts("Toggle No Buffer"))
            vim.keymap.set("n", "c", api.fs.copy.node, opts("Copy"))
            vim.keymap.set("n", "G", api.filter.git.clean.toggle, opts("Toggle Git Clean"))
            vim.keymap.set("n", "[c", api.node.navigate.git.prev, opts("Prev Git"))
            vim.keymap.set("n", "]c", api.node.navigate.git.next, opts("Next Git"))
            vim.keymap.set("n", "d", api.fs.remove, opts("Delete"))
            vim.keymap.set("n", "D", api.fs.trash, opts("Trash"))
            vim.keymap.set("n", "E", api.tree.expand_all, opts("Expand All"))
            vim.keymap.set("n", "e", api.fs.rename_basename, opts("Rename: Basename"))
            vim.keymap.set("n", "]e", api.node.navigate.diagnostics.next, opts("Next Diagnostic"))
            vim.keymap.set("n", "[e", api.node.navigate.diagnostics.prev, opts("Prev Diagnostic"))
            vim.keymap.set("n", "F", api.filter.live.clear, opts("Clean Filter"))
            vim.keymap.set("n", "f", api.filter.live.start, opts("Filter"))
            vim.keymap.set("n", "g?", api.tree.toggle_help, opts("Help"))
            vim.keymap.set("n", "gy", api.fs.copy.absolute_path, opts("Copy Absolute Path"))
            vim.keymap.set("n", "H", api.filter.dotfiles.toggle, opts("Toggle Dotfiles"))
            vim.keymap.set("n", "I", api.filter.git.ignored.toggle, opts("Toggle Git Ignore"))
            vim.keymap.set("n", "J", api.node.navigate.sibling.last, opts("Last Sibling"))
            vim.keymap.set("n", "K", api.node.navigate.sibling.first, opts("First Sibling"))
            vim.keymap.set("n", "m", api.marks.toggle, opts("Toggle Bookmark"))
            vim.keymap.set("n", "o", api.node.open.edit, opts("Open"))
            vim.keymap.set("n", "O", api.node.open.no_window_picker, opts("Open: No Window Picker"))
            vim.keymap.set("n", "p", api.fs.paste, opts("Paste"))
            -- vim.keymap.set('n', 'P',     api.node.navigate.parent,              opts('Parent Directory'))
            vim.keymap.set("n", "q", api.tree.close, opts("Close"))
            vim.keymap.set("n", "r", api.fs.rename, opts("Rename"))
            vim.keymap.set("n", "R", api.tree.reload, opts("Refresh"))
            vim.keymap.set("n", "s", api.node.run.system, opts("Run System"))
            vim.keymap.set("n", "S", api.tree.search_node, opts("Search"))
            vim.keymap.set("n", "U", api.filter.custom.toggle, opts("Toggle Hidden"))
            vim.keymap.set("n", "W", api.tree.collapse_all, opts("Collapse"))
            vim.keymap.set("n", "x", api.fs.cut, opts("Cut"))
            vim.keymap.set("n", "y", api.fs.copy.filename, opts("Copy Name"))
            vim.keymap.set("n", "Y", api.fs.copy.relative_path, opts("Copy Relative Path"))
            vim.keymap.set("n", "<2-LeftMouse>", api.node.open.edit, opts("Open"))
            vim.keymap.set("n", "<2-RightMouse>", api.tree.change_root_to_node, opts("CD"))
            -- END_DEFAULT_ON_ATTACH

            -- Mappings migrated from view.mappings.list
            --
            -- You will need to insert "your code goes here" for any mappings with a custom action_cb
            vim.keymap.set("n", "A", api.tree.expand_all, opts("Expand All"))
            vim.keymap.set("n", "?", api.tree.toggle_help, opts("Help"))
            vim.keymap.set("n", "C", api.tree.change_root_to_node, opts("CD"))
            -- vim.keymap.set('n', 'P', function()
            --     local node = api.tree.get_node_under_cursor()
            --     print(node.absolute_path)
            -- end, opts('Print Node Path'))

            vim.keymap.set("n", "Z", api.node.run.system, opts("Run System"))

            -- Preview keys
            vim.keymap.set("n", "P", preview.watch, opts("Preview (Watch)"))
            vim.keymap.set("n", "<Esc>", preview.unwatch, opts("Close Preview/Unwatch"))
            vim.keymap.set("n", "<Tab>", function()
                local ok, node = pcall(api.tree.get_node_under_cursor)
                if ok and node then
                    if node.type == "directory" then
                        api.node.open.edit()
                    else
                        preview.node(node, { toggle_focus = true })
                    end
                end
            end, opts("Preview"))
        end

        require("nvim-tree").setup({
            disable_netrw = true,
            hijack_netrw = false,
            sync_root_with_cwd = true, -- ex "update_cwd" (deprecato): la root segue la cwd di Neovim
            sort = {
                sorter = project_tree_sorter,
            },
            update_focused_file = {
                enable = false,
            },
            filters = {
                custom = project_custom_filter,
            },
            git = {
                enable = true,
                timeout = 5000, -- su Windows "git status" qui impiega ~2.4s: 500ms andava sempre in timeout
            },
            diagnostics = {
                enable = false,
                icons = { hint = "", info = "", warning = "", error = "" },
            },
            renderer = {
                add_trailing = true,
                highlight_git = "icon",
                root_folder_label = false,
                highlight_opened_files = "none",
                indent_markers = {
                    enable = true,
                },
            },
            view = {
                side = "left",
                width = 30,
                signcolumn = "yes",
                -- mappings = {
                --     list = {
                --         { key = "?", action = "toggle_help" }
                --     }
                -- }
            },
            actions = {
                use_system_clipboard = true,
                change_dir = {
                    enable = true,
                    global = false,
                    restrict_above_cwd = false,
                },
                open_file = {
                    quit_on_open = false,
                    resize_window = false,
                    window_picker = {
                        enable = true,
                        picker = function()
                            return require("window-picker").pick_window({
                                filter_rules = {
                                    file_path_contains = { "nvim-tree-preview://" },
                                },
                            })
                        end,
                        -- chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
                        exclude = {
                            filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
                            buftype = { "nofile", "terminal" },
                        },
                    },
                },
            },
            on_attach = on_attach,
        })

        require("nvim-tree-preview").setup({
            -- Keymaps for the preview window (does not apply to the tree window).
            -- Keymaps can be a string (vimscript command), a function, or a table.
            --
            -- If a table, it must contain either an 'action' or 'open' key:
            --
            -- Actions:
            --   { action = 'close', unwatch? = false, focus_tree? = true }
            --   { action = 'toggle_focus' }
            --
            -- Open modes:
            --   { open = 'edit' }
            --   { open = 'tab' }
            --   { open = 'vertical' }
            --   { open = 'horizontal' }
            --
            -- To disable a default keymap, set it to false.
            -- All keymaps are set in normal mode. Other modes are not currently supported.
            keymaps = {
                ["<Esc>"] = { action = "close", unwatch = true },
                ["P"] = { action = "toggle_focus" },
                ["<CR>"] = { open = "edit" },
                ["<C-t>"] = { open = "tab" },
                ["<C-v>"] = { open = "vertical" },
                ["<C-x>"] = { open = "horizontal" },
            },
            title_pos = "top-left",
            min_width = 10,
            min_height = 5,
            max_width = 85,
            max_height = 25,
            wrap = false, -- Whether to wrap lines in the preview window
            border = "single", -- Border style for the preview window
            -- Workaround per bug upstream: se row/col non sono forniti, nvim-tree-preview.lua
            -- chiama require('nvim-tree').config.view.side, ma le versioni recenti di
            -- nvim-tree.lua non espongono più M.config (spostato in nvim-tree.config.g) ->
            -- crash "attempt to index field 'config' (a nil value)". Fornendoli qui, il
            -- plugin salta del tutto quel percorso rotto. "left" deve restare in sync con
            -- view.side impostato sopra in nvim-tree.setup().
            win_position = {
                row = function(tree_win, size)
                    local cursor_row = vim.api.nvim_win_get_cursor(tree_win)[1] - 1
                    local topline = vim.fn.getwininfo(tree_win)[1].topline - 1
                    local relative_cursor = cursor_row - topline
                    local win_pos = vim.api.nvim_win_get_position(tree_win)
                    local screen_row = win_pos[1] + relative_cursor
                    local editor_height = vim.api.nvim_get_option_value("lines", {}) - 1
                    if screen_row + size.height > editor_height then
                        return relative_cursor - ((screen_row + size.height) - editor_height)
                    end
                    return relative_cursor
                end,
                col = function(tree_win, _)
                    return vim.fn.winwidth(tree_win) + 1
                end,
            },
        })
    end,
}

M.keybindings = function()
    local mapping = require("sphynx.core.5-mapping")
    mapping.register({
        {
            mode = { "n", "i", "v" },
            lhs = "<F4>",
            rhs = "<cmd>NvimTreeToggle<cr>",
            -- rhs = function()
            --     aux.toggle_sidebar("NvimTree")
            --     vim.cmd("NvimTreeToggle")
            -- end,
            options = { silent = true },
            description = "Open File Explorer",
        },
        {
            mode = { "n", "i", "v" },
            lhs = "<F3>",
            rhs = "<cmd>NvimTreeFindFile<cr>",
            options = { silent = true },
            description = "Find the current file and open it in file explorer",
        },
        {
            mode = { "n", "i", "v" },
            lhs = "<F2>",
            rhs = "<cmd>NvimTreeFocus<cr>",
            options = { silent = true },
            description = "Set focus in file explorer",
        },
    })
end

return M
