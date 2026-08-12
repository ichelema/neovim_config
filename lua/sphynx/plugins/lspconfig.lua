--[[
===============================================================================================
Plugin: lspconfig
===============================================================================================
Description: Configurazione del Language Server Protocol (LSP) per Neovim, che fornisce
             funzionalità di IDE come completamento, diagnostica, definizioni e riferimenti.
Status: Active
Author: neovim
Repository: https://github.com/neovim/nvim-lspconfig
Notes:
 - Migrato alla nuova API vim.lsp.config/vim.lsp.enable (Neovim 0.11+)
 - Configurato con impostazioni condivise per tutti i server LSP
 - Integrazione con CMP o Blink per l'autocompletamento
 - Diagnostica avanzata con icone e finestre di dialogo personalizzate
 - Supporto per Code Lens con aggiornamento automatico
 - Mappature personalizzate con integrazione which-key
Server LSP attivi:
 - solargraph: per Ruby, avvio ibrido: bundle exec se solargraph è nel Gemfile.lock
   del progetto, altrimenti installazione globale (mise)
 - vimls: per VimL, con indicizzazione e completamento avanzati
 - nimls: per Nim, con configurazione base
 - html: per HTML e ERB, con server da VS Code
 - jsonls: per JSON/JSONC, validazione, hover e formatter (server da VS Code)
 - cssls: per CSS/SCSS/LESS, completamento e diagnostica (server da VS Code)
 - ts_ls: per TypeScript, con formattazione integrata disabilitata
 - lua_ls: per Lua, con configurazione specifica per Neovim
 - ahk2: per AutoHotkey v2, con percorso interprete personalizzato
Caratteristiche abilitate:
 - Completamento con supporto per snippet e documentazione
 - Diagnostica in tempo reale con segni e testo virtuale
 - Finestra di diagnostica fluttuante con formattazione personalizzata
 - Code Lens con aggiornamento automatico
Caratteristiche personalizzabili:
 - Testo virtuale per diagnostica (attivabile/disattivabile)
 - Segni di diagnostica (attivabili/disattivabili)
 - Inlay hints (attivabili/disattivabili)
Da sapere:
 - Usa la nuova API nativa vim.lsp.config() invece di require('lspconfig').setup()
 - Da Neovim 0.12 i comandi sono quelli nativi :lsp enable/disable/restart/stop
   (nvim-lspconfig non definisce piu' :LspStart/:LspStop/:LspRestart/:LspInfo):
   qui :LspStart/:LspStop/:LspRestart sono ridefiniti come alias dei nativi
 - Percorsi hardcoded per alcuni server (es. AutoHotkey)
 - Supporto per più backend di completamento (cmp o blink)
Keymaps disponibili:
 - <leader>ld → Vai alla definizione
 - <leader>lk → Mostra documentazione al passaggio del mouse
 - <leader>le → Apri finestra diagnostica fluttuante
 - <leader>lv → Attiva/disattiva testo virtuale diagnostica
 - <leader>ls → Attiva/disattiva segni diagnostica
 - <leader>li → Attiva/disattiva inlay hints
 - <leader>lS → Avvia i server LSP per il filetype corrente (:LspStart)
 - <leader>lX → Ferma i server LSP attivi (:LspStop)
 - <leader>lR → Riavvia i server LSP attivi (:LspRestart)
TODO:
 - [ ] Aggiungere keybinding per code actions (<leader>la)
 - [ ] Aggiungere keybinding per riferimenti (<leader>lr)
 - [ ] Evitare percorsi hardcoded per server come AutoHotkey
 - [ ] Migliorare gestione errori per server non disponibili
 - [ ] Espandere configurazione per TypeScript
 - [ ] Aggiungere supporto per organizzazione import
 - [ ] Ottimizzare performance con pattern di file specifici
===============================================================================================
--]]

local M = {}

M.plugins = {
    ["lspconfig"] = {
        "neovim/nvim-lspconfig",
        lazy = true,
        cmd = require("sphynx.utils.lazy_load").lsp_cmds,
        ft = {
            "html",
            "typescript",
            "javascript",
            "css",
            "tex",
            "nim",
            "vim",
            "lua",
            "ruby",
            "bash",
            "sh",
        },
    },
}

M.setup = {
    ["lspconfig"] = function()
        M.keybindings()
    end,
}

M.configs = {
    ["lspconfig"] = function()
        local utils = require("sphynx.utils")

        -- Custom capabilities.
        local custom_capabilities = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.hover = { contentFormat = { "markdown", "plaintext" } }
            capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown", "plaintext" }
            capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
            capabilities.textDocument.completion.completionItem.preselectSupport = true
            capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
            capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
            capabilities.textDocument.completion.completionItem.snippetSupport = true
            -- capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
            capabilities.textDocument.signatureHelp.signatureInformation = vim.tbl_deep_extend(
                "force",
                capabilities.textDocument.signatureHelp.signatureInformation or {},
                { documentationFormat = { "markdown", "plaintext" } }
            )
            capabilities.textDocument.completion.completionItem.resolveSupport = {
                properties = {
                    "documentation",
                    "detail",
                    "additionalTextEdits",
                },
            }

            if sphynx.config.autocomplete == "cmp" then
                local cmp_nvim_lsp_present, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
                if cmp_nvim_lsp_present then
                    capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
                else
                    vim.notify(
                        "Installare cmp-nvim-lsp per autocompletamento LSP",
                        vim.log.levels.WARN,
                        { title = "Lsp", icon = " ", timeout = 5000 }
                    )
                end
            elseif sphynx.config.autocomplete == "blink" then
                local blink_cmp_present, blink_cmp = pcall(require, "blink.cmp")
                if blink_cmp_present then
                    capabilities = blink_cmp.get_lsp_capabilities(capabilities)
                else
                    vim.notify(
                        "Installare blink.cmp per autocompletamento LSP",
                        vim.log.levels.WARN,
                        { title = "Lsp", icon = " ", timeout = 5000 }
                    )
                end
            end
            return capabilities
        end

        -- Custom handlers diagnostic.
        local handlers_diagnostic = function()
            local icons = require("sphynx.ui.icons")
            local sign_config_tbl = {
                active = true, -- Attiva o disattiva i segni
                priority = 10, -- Priorità per i segni (più alto = più prioritario)
                text = {},
                texthl = {},
                numhl = {},
            }

            for tpe, icon in pairs(icons.diagnostics) do
                local hl = "DiagnosticSign" .. tpe
                sign_config_tbl.text[vim.diagnostic.severity[string.upper(tpe)]] = icon
                sign_config_tbl.texthl[vim.diagnostic.severity[string.upper(tpe)]] = hl
                sign_config_tbl.numhl[vim.diagnostic.severity[string.upper(tpe)]] = hl
            end

            vim.diagnostic.config({
                signs = sign_config_tbl,
                underline = true,
                severity_sort = true,
                update_in_insert = false,
                virtual_text = {
                    prefix = "●",
                    spacing = 4,
                    source = "if_many",
                    severity_limit = "Warning",
                },
                -- Finestra fluttuante per diagnostica dettagliata
                float = {
                    source = "always", -- Mostra sempre la fonte nella finestra fluttuante
                    border = "rounded", -- Tipo di bordo (rounded, single, double, etc.)
                    header = "", -- Intestazione della finestra (vuoto = nessuna)
                    prefix = "", -- Prefisso per ogni riga nella finestra
                    title = "Diagnostica", -- Titolo della finestra fluttuante
                    title_pos = "center", -- Posizione del titolo (left, center, right)
                    focusable = false, -- Se la finestra può prendere il focus
                    close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
                    scope = "cursor", -- Scope della diagnostica (line, cursor, buffer)
                    max_width = 80, -- Larghezza massima
                    max_height = 20, -- Altezza massima
                    -- format = function(diagnostic) -- Funzione opzionale per formattare la diagnostica
                    --   local code = diagnostic.code or (diagnostic.user_data and diagnostic.user_data.lsp.code)
                    --   local code_str = code and string.format(" [%s]", code) or ""
                    --   local severity = vim.diagnostic.severity[diagnostic.severity]
                    --   return string.format("%s%s: %s", severity:sub(1, 1), code_str, diagnostic.message)
                    -- end,
                },
            })
        end

        local lua_ls_cmd = function()
            if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
                local sumneko_root_path = vim.fn.stdpath("data") .. "/lsp/lua-language-server/"
                local sumneko_binary = sumneko_root_path .. "/bin/lua-language-server"
                return { sumneko_binary, "-E", sumneko_root_path .. "/main.lua" }
            end

            return nil
        end

        -- Risale le directory da dir fino al Gemfile.lock più vicino: se contiene
        -- solargraph ritorna la sua cartella (root del bundle), altrimenti nil.
        -- La risalita gestisce anche i file di gem vendorizzate che spediscono un
        -- proprio Gemfile senza lock (es. selenium-webdriver): il root marker cade
        -- sulla gem, ma il bundle giusto resta quello del progetto sopra.
        local solargraph_bundle_root = function(dir)
            local lockfile = vim.fs.find("Gemfile.lock", { upward = true, path = dir or vim.fn.getcwd() })[1]
            if not lockfile then
                return nil
            end
            local f = io.open(lockfile, "r")
            if not f then
                return nil
            end
            local content = f:read("*a")
            f:close()
            if content:find("solargraph", 1, true) then
                return vim.fs.dirname(lockfile)
            end
            return nil
        end

        -- Avvio SOLO via Bundler: solargraph con la versione/gem del Gemfile.lock
        -- del progetto, cwd sulla root del bundle. Se il progetto non ha solargraph
        -- nel bundle il server non parte affatto (vedi root_dir sotto): niente più
        -- shim mise globale, che era la causa dei processi orfani accumulati.
        local solargraph_ls_cmd = function(dispatchers, config)
            local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
            local cmd = { is_win and "bundle.bat" or "bundle", "exec", "solargraph", "stdio" }
            return vim.lsp.rpc.start(cmd, dispatchers, { cwd = config.root_dir })
        end

        local shared_settings = {
            capabilities = custom_capabilities(),

            handlers = {
                ["textDocument/publishDiagnostics"] = handlers_diagnostic(),
            },

            flags = {
                debounce_text_changes = 150,
            },

            on_attach = function(client, bufnr)
                if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].buflisted then
                    -- è un buffer temporaneo, tipo preview → ignoriamo
                    return
                end
                vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", { buf = bufnr })

                -- Disabilita il formatter incorporato per alcuni client
                if client.name == "tsserver" then
                    client.server_capabilities.documentFormattingProvider = false
                end

                -- code lens
                if client:supports_method("textDocument/codeLens", { bufnr = bufnr }) then
                    vim.lsp.codelens.enable(true, { bufnr = bufnr })
                end

                -- print(string.format("LSP '%s' attivo", client.name))
            end,
        }

        local servers = {

            solargraph = {
                -- Configurazione specifica per solargraph: cmd è una funzione,
                -- risolta a ogni avvio in base alla root del progetto (vedi sopra)
                cmd = solargraph_ls_cmd,
                autostart = true,
                flags = { debounce_did_change_notify = 150, allow_incremental_sync = true },
                -- Aggancia SOLO se il progetto ha solargraph nel Gemfile.lock:
                -- on_dir viene chiamato solo in quel caso, altrimenti niente server.
                root_dir = function(bufnr, on_dir)
                    local root = solargraph_bundle_root(vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
                    if root then
                        on_dir(root)
                    end
                end,
                filetypes = { "ruby", "rakefile", "rb", "erb" },
                settings = {
                    solargraph = {
                        completion = true,
                        definitions = true,
                        references = true,
                        hover = true,
                        diagnostics = true,
                        autoformat = false,
                        formatting = true,
                        folding = false,
                        useBundler = false,
                    },
                },
            },

            -- ruby_lsp = {
            --     autostart = true;
            --     flags = {debounce_did_change_notify = 150, allow_incremental_sync = true},
            --     handlers = {
            --         ['textDocument/publishDiagnostics'] = handlers_diagnostic(),
            --     }
            -- },

            vimls = {
                detached = false,
                flags = { debounce_did_change_notify = 150, allow_incremental_sync = true },
                -- Configurazione specifica per vimls
                init_options = {
                    iskeyword = "@,48-57,_,192-255,-#",
                    vimruntime = "",
                    runtimepath = "",
                    diagnostic = {
                        enable = true,
                    },
                    indexes = {
                        runtimepath = true,
                        gap = 100,
                        count = 3,
                        projectRootPatterns = { "runtime", "nvim", ".git", "autoload", "plugin" },
                    },
                    suggest = {
                        fromRuntimepath = true,
                        fromVimruntime = true,
                    },
                },
            },

            nimls = {
                detached = false,
                cmd = { "cmd", "/c", "nimlsp.cmd" },
            },

            html = {
                detached = false,
                flags = { debounce_did_change_notify = 150 },
                cmd = { "vscode-html-language-server.cmd", "--stdio" },
                filetypes = { "eruby", "html" },
            },

            cssls = {
                detached = false,
                cmd = { "vscode-css-language-server.cmd", "--stdio" },
                filetypes = { "css", "scss", "less" },
            },

            jsonls = {
                detached = false,
                cmd = { "vscode-json-language-server.cmd", "--stdio" },
                filetypes = { "json", "jsonc" },
                -- Il formatter va richiesto esplicitamente all'init
                init_options = { provideFormatter = true },
                settings = {
                    json = {
                        -- Catalogo SchemaStore: associa gli schemi ai file di config
                        -- noti dal nome (package.json, tsconfig.json, ...)
                        schemas = require("schemastore").json.schemas(),
                        validate = { enable = true },
                    },
                },
            },

            ts_ls = {
                detached = false,
            },

            lua_ls = {
                capabilities = custom_capabilities(),
                cmd = lua_ls_cmd(),
                autostart = true,
                flags = { debounce_did_change_notify = 150, allow_incremental_sync = true },
                handlers = {
                    ["textDocument/publishDiagnostics"] = handlers_diagnostic(),
                },
                settings = {
                    Lua = {
                        runtime = {
                            -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                            version = "LuaJIT",
                            -- Setup your lua path
                            path = {
                                vim.split(package.path, ";"),
                                "lua/?.lua",
                                "lua/?/init.lua",
                            },
                        },
                        diagnostics = {
                            -- Get the language server to recognize the `vim` global
                            globals = { "vim", "nvim_config", "sphynx" },
                            disable = { "lowercase-global", "missing-fields" },
                            unusedLocalExclude = { "_*" },
                        },
                        workspace = {
                            checkThirdParty = false,
                            -- Make the server aware of Neovim runtime files
                            library = vim.api.nvim_get_runtime_file("", true),
                            -- Non scansionare .git (e .vscode) per evitare ri-scan a ogni
                            -- operazione git mentre nvim e' aperto
                            ignoreDir = { ".vscode", ".git", "Neovim Doc" },
                            -- adjust these two values if your performance is not optimal
                            maxPreload = 2000,
                            preloadFileSize = 1000,
                        },
                        telemetry = {
                            enable = false,
                        },
                    },
                },
            },

            ahk2 = {
                autostart = true,
                cmd = {
                    "node",
                    vim.fn.expand(
                        "C:/Users/en27553/AppData/Local/nvim-data/lsp/vscode-autohotkey2-lsp/server/dist/server.js"
                    ),
                    "--stdio",
                },
                filetypes = { "ahk", "autohotkey", "ah2" },
                init_options = {
                    locale = "en-us",
                    InterpreterPath = "C:/APPL/AutoHotkey/v2/AutoHotkey64.exe",
                    -- InterpreterPath = "C:/APPL/AutoHotkey/AutoHotkey.exe",
                    -- Same as initializationOptions for Sublime Text4, convert json literal to lua dictionary literal
                },
                single_file_support = true,
                flags = { debounce_text_changes = 500 },
            },

            bashls = {
                cmd = { "bash-language-server", "start" },
                autostart = true,
                single_file_support = false,
                settings = {
                    bashIde = {
                        -- Glob pattern for finding and parsing shell script files in the workspace.
                        -- Used by the background analysis features across files.

                        -- Prevent recursive scanning which will cause issues when opening a file
                        -- directly in the home directory (e.g. ~/foo.sh).
                        --
                        -- Default upstream pattern is "**/*@(.sh|.inc|.bash|.command)".
                        globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
                    },
                },
                filetypes = { "bash", "sh" },
                root_markers = { ".git" },
            },
        }

        -- Configura ogni server usando la nuova API vim.lsp.config
        for server_name, server_config in pairs(servers) do
            -- Unisci configurazioni condivise e specifiche
            local config = vim.tbl_deep_extend("force", shared_settings, server_config)

            -- Salva la funzione on_attach originale
            local original_on_attach = config.on_attach

            -- Sovrascrivi on_attach per combinare generale e specifico
            if server_config.on_attach then
                config.on_attach = function(client, bufnr)
                    original_on_attach(client, bufnr)
                    server_config.on_attach(client, bufnr)
                end
            end

            -- Rimuovi campi non compatibili con vim.lsp.config
            config.on_setup = nil

            -- Configura il server con la nuova API
            vim.lsp.config(server_name, config)

            -- Abilita il server per i suoi filetypes
            vim.lsp.enable(server_name)
        end

        -- Su Neovim 0.12 nvim-lspconfig non definisce piu' i comandi :Lsp*
        -- (plugin/lspconfig.lua esce subito se esiste il comando nativo :lsp):
        -- li ridefiniamo come alias dei sottocomandi nativi, cosi' restano
        -- validi sia digitati sia come trigger lazy (vedi lazy_load.lsp_cmds)
        vim.api.nvim_create_user_command("LspStart", function(info)
            vim.cmd("lsp enable " .. info.args)
        end, { nargs = "*", desc = "Avvia i server LSP (alias di :lsp enable)" })
        vim.api.nvim_create_user_command("LspStop", function(info)
            vim.cmd("lsp stop " .. info.args)
        end, { nargs = "*", desc = "Ferma i server LSP (alias di :lsp stop)" })
        vim.api.nvim_create_user_command("LspRestart", function(info)
            vim.cmd("lsp restart " .. info.args)
        end, { nargs = "*", desc = "Riavvia i server LSP (alias di :lsp restart)" })
    end,
}

M.keybindings = function()
    local mapping = require("sphynx.core.5-mapping")
    local wk = require("which-key")
    local prefix = "<leader>l"

    -- Funzione per attivare/disattivare il testo virtuale
    local virtual_text_enabled = true
    local function toggle_virtual_text()
        virtual_text_enabled = not virtual_text_enabled
        vim.diagnostic.config({
            virtual_text = virtual_text_enabled and {
                prefix = "●",
                source = "if_many",
            } or false,
        })
        print("Virtual Text: " .. (virtual_text_enabled and "ON" or "OFF"))
    end

    -- Funzione per attivare/disattivare i segni
    local signs_enabled = true
    local function toggle_signs()
        signs_enabled = not signs_enabled
        vim.diagnostic.config({
            signs = signs_enabled,
        })
        print("Diagnostic Signs: " .. (signs_enabled and "ON" or "OFF"))
    end

    -- Funzione per attivare/disattivare hints
    local function toggle_hints()
        local current_buf = vim.api.nvim_get_current_buf()
        local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = current_buf })
        vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = current_buf })

        print("Inlay Hints: " .. (not is_enabled and "ON" or "OFF"))
    end

    wk.add({
        { prefix, group = "󰁨 LSP" },
        { prefix .. "d", "<Cmd>lua vim.lsp.buf.definition()<CR>", desc = "Go definition" },
        { prefix .. "k", "<Cmd>lua vim.lsp.buf.hover()<CR>", desc = "Hover doc" },
        { prefix .. "a", "<Cmd>lua vim.lsp.buf.code_action()<CR>", desc = "Code action" },
        { prefix .. "e", "<Cmd>lua vim.diagnostic.open_float()<CR>", desc = "Apri diagnostica flottante" },
        { prefix .. "f", "<Cmd>lua vim.lsp.buf.format({ async = true })<CR>", desc = "Format file" },
        { prefix .. "v", toggle_virtual_text, desc = "Toggle diagnostic virtual text" },
        { prefix .. "s", toggle_signs, desc = "Toggle diagnostic signs" },
        { prefix .. "i", toggle_hints, desc = "Toggle Inlay Hints" },
        -- Gestione server: comandi forniti da nvim-lspconfig (sono anche i
        -- trigger di lazy loading, vedi lazy_load.lsp_cmds)
        { prefix .. "S", "<Cmd>LspStart<CR>", desc = "Start server LSP" },
        { prefix .. "X", "<Cmd>LspStop<CR>", desc = "Stop server LSP" },
        { prefix .. "R", "<Cmd>LspRestart<CR>", desc = "Restart server LSP" },
    }, mapping.opt_mappping)
end

return M

-- nvim_lsp.ruby_lsp.setup {
--     capabilities = capabilities,
--     autostart = true;
--     on_attach = lsp_on_attach,
--     flags = {debounce_did_change_notify = 150, allow_incremental_sync = true},
--     handlers = {
--         ['textDocument/publishDiagnostics'] = handlers_diagnostic(),
--     }
-- }

-- if client.server_capabilities.inlayHintProvider then
--     vim.notify("Inlay hint abilitato")
--     vim.lsp.inlay_hint.enable(true, {bufnr = bufnr})
-- end

-- DECOMMENTARE LE SEGUENTI LINEE PER USARE RUBY-LSP
-- _timers = {}
-- local function setup_diagnostics(client, buffer)
-- if require("vim.lsp.diagnostic")._enable then
--     return
-- end

-- local diagnostic_handler = function()
--     local params = vim.lsp.util.make_text_document_params(buffer)
--     client.request("textDocument/diagnostic", { textDocument = params }, function(err, result)
--     if err then
--         local err_msg = string.format("diagnostics error - %s", vim.inspect(err))
--         vim.lsp.log.error(err_msg)
--     end
--     local diagnostic_items = {}
--     if result then
--         diagnostic_items = result.items
--     end
--     vim.lsp.diagnostic.on_publish_diagnostics(
--         nil,
--         vim.tbl_extend("keep", params, { diagnostics = diagnostic_items }),
--         { client_id = client.id }
--     )
--     end)
-- end

-- diagnostic_handler() -- to request diagnostics on buffer when first attaching

-- vim.api.nvim_buf_attach(buffer, false, {
--     on_lines = function()
--     if _timers[buffer] then
--         vim.fn.timer_stop(_timers[buffer])
--     end
--     _timers[buffer] = vim.fn.timer_start(200, diagnostic_handler)
--     end,
--     on_detach = function()
--     if _timers[buffer] then
--         vim.fn.timer_stop(_timers[buffer])
--     end
--     end,
-- })
-- end

-- -- adds ShowRubyDeps command to show dependencies in the quickfix list.
-- -- add the `all` argument to show indirect dependencies as well
-- local function add_ruby_deps_command(client, bufnr)
--     vim.api.nvim_buf_create_user_command(bufnr, "ShowRubyDeps",
--                                         function(opts)

--         local params = vim.lsp.util.make_text_document_params()

--         local showAll = opts.args == "all"

--         client.request("rubyLsp/workspace/dependencies", params,
--                         function(error, result)
--             if error then
--                 print("Error showing deps: " .. error)
--                 return
--             end

--             local qf_list = {}
--             for _, item in ipairs(result) do
--                 if showAll or item.dependency then
--                     table.insert(qf_list, {
--                         text = string.format("%s (%s) - %s",
--                                             item.name,
--                                             item.version,
--                                             item.dependency),

--                         filename = item.path
--                     })
--                 end
--             end

--             vim.fn.setqflist(qf_list)
--             vim.cmd('copen')
--         end, bufnr)
--     end, {nargs = "?", complete = function()
--         return {"all"}
--     end})
-- end

-- setup_diagnostics(client, bufnr)
-- add_ruby_deps_command(client, bufnr)
