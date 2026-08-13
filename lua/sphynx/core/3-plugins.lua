sphynx.modules = {}

local theme = function()
    if
        ({
            nightfox = true,
            dayfox = true,
            dawnfox = true,
            duskfox = true,
            nordfox = true,
            terafox = true,
            carbonfox = true,
        })[sphynx.config.colorscheme]
    then
        return "nightfox"
    else
        return "onenord"
    end
end

-- List modules
local modules = {
    --{{{ Theme
    theme(),
    --}}} Theme

    --{{{ CORE
    "core",
    --}}} CORE

    --{{{ UI
    "ufo",
    "illuminate",               -- OK - Evidenzia altre occorrenze della parola
    "vim-mark",                 -- OK - Evidenzia parole/pattern con colori persistenti (stile evidenziatore)
    "foldsigns",                -- Ok - Gestisce la visualizzazione dei segni (signs) nelle sezioni di codice piegate
    "heirline",                 -- Ok - Statusline, Winbar
    "incline",                  -- OK - Nome file per finestra (floating), sostituisce il winbar di heirline
    "indent-blankline",         -- OK - Migliora indentazione mostrando linee visive
    "devicons",                 -- OK - Aggiunge icone colorate per i file
    "smoothcursor",             -- OK - Animazione sulla barra sinistra quando mi sposto, miglioramento visivo
    "colorful-winsep",          -- OK - Colora il bordo della finestra attiva (split con focus)
    "bqf",                      -- OK - Migliorare la finestra quickfix
    "rainbow-delimiters",       -- OK - Mostra le parentesi colorate
    --}}} UI

    --{{{ MAPPING
    "which-key",                -- OK - Visualizza una finestra popup con i possibili tasti e combinazioni disponibili
    --}}} MAPPING

    --{{{ LSP
    "lspconfig",                -- OK - Configurazione del Language Server Protocol (LSP)
    "lazydev",                  -- OK - Migliore esperienza di sviluppo Lua in Neovim
    "floating-tag-preview",     -- OK - Visualizza i tag in una floating window vicino al cursore
    "dd",                       -- OK - Si occupa di rimandare (defer) tutti i diagnostici
    "goto-preview",             -- OK - Visualizza in finestre flottanti le anteprime dei risultati delle funzioni LSP
    "schemastore",              -- OK - Catalogo JSON Schema (SchemaStore.org) usato da jsonls per i file di config noti
    "glance",                   -- OK - Finestra di preview stile VSCode per esplorare definizioni, riferimenti, implementazioni e type definitions via LSP
    --}}} LSP

    --{{{ COMPLETION
    "blink",                    -- OK - Autocompletamento asincrono
    "autopair",                 -- OK - Inserimento automatico e la gestione di coppie di caratteri
    --}}} COMPLETION

    --{{{ DEBUG
    "dap",                      -- OK - Debug
    "dap-virtual-text",         -- OK - Mostra valore variabili inline
    "dap-telescope",            -- OK - Integrazione dap con telescope
    --}}} DEBUG

    --{{{ LANGUAGE
    "ruby-interpolation",       -- OK - Aggiunge l'interpolazione delle stringhe Ruby
    "render-markdown",          -- OK - Rendering Markdown nel buffer (heading, code, callout, checkbox)
    -- "image",                 -- OK - Rendering immagini inline (Sixel) nei file Markdown
    --}}} LANGUAGE

    --{{{ FILE BROWSER AND NAVIGATION
    "nvim-tree",                -- OK - File explorer (sidebar)
    "telescope",                -- OK - Fuzzy finder estendibile: cerca, filtra, anteprima e seleziona file
    "cybu",                     -- OK - Switch buffer con Tab come windows
    "nvim-window-picker",       -- OK - Mi permette di passage da una finestra all'altra in modo molto rapido
    "maximizer",                -- OK - Massimizza/ripristina la finestra
    "workspace",                -- OK - Tab come workspace stile i3 (buffer isolati per tab); comandi WS/WSbmv, <leader>w
    "matchup",                  -- OK - Estende il % di Vim a parole specifiche del linguaggio
    "hop",                      -- OK - Motion plugin in stile EasyMotion
    "marks",                    -- OK - Potenzia i mark nativi di Vim
    --}}} FILE BROWSER AND NAVIGATION

    --{{{ SEARCH
    "hlslens",                  -- OK - Mostra indice/totale delle corrispondenze di ricerca accanto a ognuna (lens)
    "grepper",                  -- OK - Ricerca testo (rg/git) con risultati in quickfix/side, integrato con nvim-bqf
    --}}} SEARCH

    --{{{ GIT
    "gitsigns",                 -- OK - Segni git nel gutter, navigazione/preview/blame degli hunk
    "diffview",                 -- OK - Vista diff a schermo intero: modifiche, commit/branch e file history
    --}}} GIT

    --{{{ AI
    "claudecode",               -- OK - Integrazione IDE con Claude Code CLI (WebSocket, invio selezione al terminale)
    --}}} AI

    --{{{ EDITING
    "comment",                  -- OK - Commenta e decommenta righe singole e selezioni visuali
    "treehopper",               -- OK - mi permette con "~" di selezionare attraverso hop i nodi di treesitter
    "smart-paste",              -- OK - Paste intelligente: reindenta il contenuto incollato (p/P/gp/gP)
    --}}} EDITING

    -- {{{ MISC
    "treesitter",               -- OK - Parsing incrementale del codice per evidenziazione sintattica
    "treesitter-textobjects",   -- OK - mi permette di selezionare metodi o classi usando treesitter
    "noice",                    -- OK - Sostituisce la UI di messaggi/cmdline/popupmenu
    "color",                    -- OK - Color picker grafico (Oklch) + highlight async dei colori nel buffer
    "neoformat",                -- OK - Formattatore multi-linguaggio (tsfmt per TS, shfmt per sh/bash), <F8>
    "neoterm",                  -- OK - Terminale integrato per debug Ruby con PRY (:T, invio a REPL, breakpoint)
    "kitty-scrollback",         -- OK - Scrollback di Kitty dentro Neovim (solo Linux); lancio via kitten Ctrl+Shift+H
    "neoscroll",                -- OK - Scrolling fluido animato (smooth scroll) su <localleader>+frecce
    "neoclip",                  -- OK - Clipboard manager: cronologia degli yank via Telescope (<leader>ty)
    "surround",                 -- OK - Surround di coppie (virgolette/parentesi/tag); in Visual seleziona e premi il delimitatore
    "todo-comments",            -- OK - Evidenzia/cerca i commenti TODO/FIX/HACK; jump con <leader>x frecce
    "trouble",                  -- OK - Lista navigabile di diagnostics, riferimenti LSP, symbols e quickfix/loclist; <leader>k
    "aerial",                   -- OK - Mostra una finestra con la struttura (outline) del codice
    -- "nvim-pasta",               -- Disabilitato: sostituito da smart-paste (conflitto su p/P)
    "sayonara",                 -- OK - Chiusura intelligente di buffer/finestra; bc mantiene la finestra, bC la chiude
    "virtcolumn",               -- OK - Disegna una colonna verticale per mostrami quando riga troppo lunga
    "tabby",                    -- OK - Line buffer e tab
    -- --}}} MISC

    -- ============================================================
    -- PLUGIN DISABILITATI - scommenta una riga per riattivare
    -- ============================================================

    --{{{ DISABLED UI
    -- "satellite",
    -- "scrollview", -- Barra di scorrimento
    --}}} DISABLED UI

    --{{{ DISABLED LSP
    -- "lspsaga",
    -- "lsp_signature",
    -- "lsp-smag",              -- sostituito dal tagfunc nativo (vim.lsp.tagfunc, automatico su LspAttach)
    --}}} DISABLED LSP

    --{{{ DISABLED COMPLETION
    -- "luasnip",
    -- "cmp",
    -- "cmp-cmdline",
    --}}} DISABLED COMPLETION

    --{{{ DISABLED DEBUG
    -- "one-small-step-for-vimkind",
    --}}} DISABLED DEBUG

    --{{{ DISABLED LANGUAGE
    -- "nim",
    -- "markdown-preview",         -- OK - Anteprima live nel browser per i file Markdown
    -- "markdown",                 -- vim-markdown: conceal in conflitto con render-markdown, tenuto disabilitato
    --}}} DISABLED LANGUAGE

    --{{{ DISABLED FILE BROWSER AND NAVIGATION
    -- "window",
    -- "windowswap",
    -- "scope",
    -- "clap",
    --}}} DISABLED FILE BROWSER AND NAVIGATION

    --{{{ DISABLED EDITING
    -- "spaceless", -- Rimuove automaticamente gli spazi finali
    --}}} DISABLED EDITING

    --{{{ DISABLED MISC
    -- "faster",
    -- "focus",
    -- "tabular",
    -- "vimade",
    -- "symbols-outline",
    -- "vista",
    --}}} DISABLED MISC
}

-- Install Lazy if not found
local function setup_lazy()
    if not vim.uv.fs_stat(sphynx.path.plugin_lazy_folder) then
        local output = vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "--single-branch",
            "https://github.com/folke/lazy.nvim.git",
            sphynx.path.plugin_lazy_folder,
        })
        if vim.api.nvim_get_vvar("shell_error") ~= 0 then
            vim.api.nvim_err_writeln("Error cloning lazy.nvim repository...\n\n" .. output)
        end
        vim.opt.cmdheight = 1
        vim.cmd("redraw")
        vim.api.nvim_echo({ { "  Please wait while plugins are installed...", "Bold" } }, true, {})
    end

    vim.opt.runtimepath:prepend(sphynx.path.plugin_lazy_folder)
end

-- Insert in global sphynx.modules all module
local function set_modules_config()
    for _, module in ipairs(modules) do
        local ok, result = xpcall(require, debug.traceback, string.format("sphynx.plugins.%s", module))
        if ok then
            sphynx.modules[module] = result
        else
            vim.notify(result, vim.log.levels.WARN, { title = "Plugins", icon = "󰏗 ", timeout = 5000 })
        end
    end
end

-- Read from sphynx.modules plugins configurations
local function read_plugin_config()
    local plugins = {}

    set_modules_config()

    for mod_name, mod in pairs(sphynx.modules) do
        for plugin, lazy_spec in pairs(mod.plugins) do
            if mod.setup and mod.setup[plugin] and type(mod.setup[plugin]) == "function" then
                lazy_spec["init"] = mod.setup[plugin]
            end
            if mod.configs and mod.configs[plugin] and type(mod.configs[plugin]) == "function" then
                lazy_spec["config"] = mod.configs[plugin]
            end
            table.insert(plugins, lazy_spec)
        end
        -- if mod.keybindings then
        --     mod.keybindings()
        -- end
    end

    return plugins
end

-- Autostart function to initialize all plugins
Plugin_setup = (function()
    setup_lazy()

    local present, lazy = pcall(require, "lazy")

    if not present then
        return
    end

    lazy.setup(read_plugin_config(), {
        root = sphynx.path.plugin_folder,
        lockfile = sphynx.path.nvim_config .. "/lazy-lock.json", -- lockfile generated after running update.
        -- leave nil when passing the spec as the first argument to setup()
        spec = nil, ---@type LazySpec
        local_spec = true, -- load project specific .lazy.lua spec files. They will be added at the end of the spec.
        defaults = {
            lazy = true,
        },
        concurrency = 20,
        diff = {
            cmd = "git",
        },
        install = { colorscheme = { "nordfox" } },
        git = {
            -- defaults for the `Lazy log` command
            -- log = { "-10" }, -- show the last 10 commits
            log = { "--since=7 days ago" }, -- show commits from the last 3 days
            timeout = 60, -- kill processes that take more than 1 minutes
            url_format = "https://github.com/%s.git",
            -- lazy.nvim requires git >=2.19.0. If you really want to use lazy with an older version,
            -- then set the below to false. This is should work, but is NOT supported and will
            -- increase downloads a lot.
            filter = true,
        },
        pkg = {
            enabled = true,
            cache = vim.fn.stdpath("state") .. "/lazy/pkg-cache.lua",
            -- the first package source that is found for a plugin will be used.
            sources = {
                "lazy",
                "rockspec",     -- will only be used when rocks.enabled is true
                "packspec",
            },
        },
        rocks = {
            enabled = true,
            root = vim.fn.stdpath("data") .. "/lazy-rocks",
            server = "https://nvim-neorocks.github.io/rocks-binaries/",
            -- use hererocks to install luarocks?
            -- set to `nil` to use hererocks when luarocks is not found
            -- set to `true` to always use hererocks
            -- set to `false` to always use luarocks
            hererocks = nil,
        },
        performance = {
            cache = {
                enabled = true,
            },
            reset_packpath = true,
            rtp = {
                reset = true,
                paths = {
                    sphynx.path.nvim_config,
                },
                disabled_plugins = {
                    "loaded_python3_provider",
                    "python_provider",
                    "node_provider",
                    "ruby_provider",
                    "perl_provider",
                    "2html_plugin",
                    "getscript",
                    "getscriptPlugin",
                    "gzip",
                    "tar",
                    "tarPlugin",
                    "rrhelper",
                    "vimball",
                    "vimballPlugin",
                    "zip",
                    "zipPlugin",
                    "tutor",
                    "rplugin",
                    "logiPat",
                    "netrwSettings",
                    "netrwFileHandlers",
                    "syntax",
                    "synmenu",
                    "optwin",
                    "compiler",
                    "bugreport",
                    "ftplugin",
                    "load_ftplugin",
                    "indent_on",
                    "netrwPlugin",
                    "tohtml",
                    "man",
                },
            },
        },
        -- lazy can generate helptags from the headings in markdown readme files,
        -- so :help works even for plugins that don't have vim docs.
        -- when the readme opens with :help it will be correctly displayed as markdown
        readme = {
            enabled = false,
        },
        change_detection = {
            -- automatically check for config file changes and reload the ui
            enabled = false,
            notify = false, -- get a notification when changes are found
        },
    })
end)()
