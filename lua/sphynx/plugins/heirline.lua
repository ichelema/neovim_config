--[[
===============================================================================================
Plugin: heirline.nvim
===============================================================================================
Description: Un plugin di statusline estremamente configurabile per Neovim che permette di
             personalizzare completamente la statusline, winbar e altri elementi dell'UI.
Status: Active
Author: rebelot
Repository: https://github.com/rebelot/heirline.nvim
Notes:
 - Caricamento lazy tramite condizione che verifica l'assenza di gonvim_running
 - Configurazione della statusline con impostazione globale (laststatus = 3)
 - Monitoraggio dello stato Git tramite fs_event/fs_poll in base al sistema operativo
 - Visualizzazione completa di: modalità Vim, branch Git, percorso file, diagnostiche LSP
 - Personalizzazione dei colori basata sul colorscheme attivo tramite sphynx.colors
 - Supporto per finestre speciali (NvimTree, terminal, help, quickfix, ecc.)
 - Winbar con nome file, icona, stato di modifica e pulsante di chiusura
 - Disattivazione automatica della winbar per tipi di buffer specifici
 - Gestione flessibile dello spazio disponibile con priorità di visualizzazione
 - Aggiornamento dei colori automatico quando cambia il colorscheme

Keymaps:
 - Click sul client LSP → Apre LspInfo
 - Click sulle diagnostiche → Apre Telescope diagnostics
 - Click sul pulsante di chiusura → Chiude la finestra corrente

Componenti principali:
 - ViMode: Visualizza la modalità corrente di editing con colori dedicati
 - GitBranch: Mostra il branch Git corrente con aggiornamento automatico
 - FileNameBlock: Combinazione di icona, nome file e indicatori di modifica
 - Diagnostics: Mostra conteggio di errori, warning, info e hint
 - LspClient: Visualizza il client LSP attivo per il buffer corrente
 - Path: Mostra il percorso del file con opzioni adattive
 - ScrollBar: Indicatore grafico della posizione nel documento
 - WinBar: Personalizzazione della barra superiore per ogni finestra

TODO:
 - [ ] Implementare visualizzazione del progresso LSP per operazioni lunghe
 - [ ] Ottimizzare ulteriormente il monitoraggio Git per repository grandi
 - [ ] Considerare l'utilizzo di statuscolumn per gutter numerazione e segni
 - [ ] Aggiungere indicatore di stato per modalità Macro recording
 - [ ] Valutare migliori strategie di caching per prestazioni in file grandi
===============================================================================================
--]]

local M = {}

M.plugins = {
    ["heirline"] = {
        "rebelot/heirline.nvim",
        lazy = true,
        event = "UIEnter",
        dependencies = { "kyazdani42/nvim-web-devicons" },
        cond = function()
            return not vim.g.gonvim_running
        end,
    },
}


M.configs = {
    ["heirline"] = function()
        vim.opt.laststatus = 3

        local heirline = require("heirline")
        local conditions = require("heirline.conditions")
        local utils = require("heirline.utils")
        local colors = require("sphynx.colors").get_color()
        local Align = { provider = "%=" }
        local Space = { provider = " " }
        local Break = { provider = "%<" } -- this means that the statusline is cut here when there's not enough space
        local BigSpace = { provider = (" "):rep(5) }

        -- require("heirline").load_colors(colors)

        local function is_available(plugin)
            local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
            return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
        end

        local ViMode = {
            -- get vim current mode, this information will be required by the provider
            -- and the highlight functions, so we compute it only once per component
            -- evaluation and store it as a component attribute
            init = function(self)
                self.mode = vim.fn.mode(1) -- :h mode()
            end,
            -- Now we define some dictionaries to map the output of mode() to the
            -- corresponding string and color. We can put these into `static` to compute
            -- them at initialisation time.
            static = {
                mode_names = { -- change the strings if yow like it vvvvverbose!
                    ["n"] = "NORMAL",
                    ["no"] = "O-PENDING",
                    ["nov"] = "O-PENDING",
                    ["noV"] = "O-PENDING",
                    ["no\22"] = "O-PENDING",
                    ["niI"] = "NORMAL",
                    ["niR"] = "NORMAL",
                    ["niV"] = "NORMAL",
                    ["nt"] = "NORMAL",
                    ["v"] = "VISUAL",
                    ["vs"] = "VISUAL",
                    ["V"] = "V-LINE",
                    ["Vs"] = "V-LINE",
                    ["\22"] = "V-BLOCK",
                    ["\22s"] = "V-BLOCK",
                    ["s"] = "SELECT",
                    ["S"] = "S-LINE",
                    ["\19"] = "S-BLOCK",
                    ["i"] = "INSERT",
                    ["ic"] = "INSERT",
                    ["ix"] = "INSERT",
                    ["R"] = "REPLACE",
                    ["Rc"] = "REPLACE",
                    ["Rx"] = "REPLACE",
                    ["Rv"] = "V-REPLACE",
                    ["Rvc"] = "V-REPLACE",
                    ["Rvx"] = "V-REPLACE",
                    ["c"] = "COMMAND",
                    ["cv"] = "EX",
                    ["ce"] = "EX",
                    ["r"] = "REPLACE",
                    ["rm"] = "MORE",
                    ["r?"] = "CONFIRM",
                    ["!"] = "SHELL",
                    ["t"] = "TERMINAL",
                },
            },
            -- We can now access the value of mode() that, by now, would have been
            -- computed by `init()` and use it to index our strings dictionary.
            -- note how `static` fields become just regular attributes once the
            -- component is instantiated.
            -- To be extra meticulous, we can also add some vim statusline syntax to
            -- control the padding and make sure our string is always at least 2
            -- characters long
            provider = function(self)
                return "%2(" .. " " .. self.mode_names[self.mode] .. " " .. "%)"
            end,
            -- Re-evaluate the component only on ModeChanged event!
            -- Also allorws the statusline to be re-evaluated when entering operator-pending mode
            update = {
                "ModeChanged",
                pattern = "*:*",
                callback = vim.schedule_wrap(function()
                    vim.cmd("redrawstatus")
                end),
            },
        }

        local GitBranch = {
            condition = conditions.is_git_repo,

            init = function(self)
                self.branch = vim.b.gitsigns_head or ""
            end,

            provider = function(self)
                return vim.trim(("%s %s"):format(#self.branch > 0 and "" or "", self.branch))
            end,

            hl = function(self)
                local color = self:mode_color()
                return { fg = color, bold = true }
            end,

            update = {
                "User",
                pattern = "GitSignsUpdate",
                callback = vim.schedule_wrap(function()
                    vim.cmd("redrawstatus")
                end),
            },
        }

        local FileNameBlock = {
            -- let's first set up some attributes needed by this component and it's children
            init = function(self)
                self.filename = vim.api.nvim_buf_get_name(0)
            end,
        }

        local FileIcon = {
            init = function(self)
                local filename = self.filename
                local extension = vim.fn.fnamemodify(filename, ":e")
                self.icon, self.icon_color =
                    require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
            end,

            provider = function(self)
                return self.icon and (" " .. self.icon .. " ")
            end,

            hl = function(self)
                return { fg = self.icon_color }
            end,
        }

        local FileName = {
            init = function(self)
                -- self.lfilename = vim.fn.fnamemodify(self.filename, ":t")
                self.lfilename = vim.fn.fnamemodify(self.filename, ":.")
                if self.lfilename == "" then
                    self.lfilename = "[No Name]"
                end
                if not conditions.width_percent_below(#self.lfilename, 0.25) then
                    self.lfilename = vim.fn.pathshorten(self.lfilename)
                end
            end,

            flexible = 2,

            {
                provider = function(self)
                    return " " .. self.lfilename .. " "
                end,
            },
            {
                provider = function(self)
                    return " " .. vim.fn.pathshorten(self.lfilename)
                end,
            },
        }

        local FileFlags = {
            {
                condition = function()
                    return vim.bo.modified
                end,
                provider = "[+]",
                hl = { fg = "green" },
            },
            {
                condition = function()
                    return not vim.bo.modifiable or vim.bo.readonly
                end,
                provider = "",
                hl = { fg = "orange" },
            },
        }

        local FileNameModifer = {
            hl = function()
                if vim.bo.modified then
                    -- use `force` because we need to override the child's hl foreground
                    return { fg = "cyan", bold = true, force = true }
                end
            end,
        }

        local FileType = {
            FileIcon,
            {
                provider = function(self)
                    local buffer = vim.bo[self and self.bufnr or 0]
                    return string.upper(buffer.filetype)
                end,
                hl = { fg = "grey2" },
            },
        }

        local TerminalName = {
            -- condition = function()
            --     return vim.bo.buftype == 'terminal'
            -- end,
            -- icon = ' ', -- 
            {
                provider = function()
                    local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
                    return " " .. tname
                end,
                hl = { fg = "blue", bold = true },
            },
            { provider = " - " },
            {
                provider = function()
                    return vim.b.term_title
                end,
            },
            -- {
            --     provider = function()
            --         local id = require("terminal"):current_term_index() --[[ .active_terminals':get_current_buf_terminal():get_index() ]]
            --         return " " .. (id or "Exited")
            --     end,
            --     hl = { bold = true, fg = "blue" },
            -- },
        }

        local LspClient = {
            condition = conditions.lsp_attached,

            static = {
                msg = "no active lsp",
                icon = " LSP: ",
            },

            init = function(self)
                self.buf_ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
                self.clients = vim.lsp.get_clients({ bufnr = 0 })
            end,

            provider = function(self)
                if next(self.clients) == nil then
                    return self.icon .. self.msg
                end
                for _, client in ipairs(self.clients) do
                    local filetypes = client.config.filetypes
                    if filetypes and vim.fn.index(filetypes, self.buf_ft) ~= -1 then
                        return self.icon .. client.name
                    end
                end
                return self.icon .. self.msg
            end,

            hl = { fg = "grey2" },

            update = { "LspAttach", "LspDetach", "WinEnter" },

            on_click = {
                name = "heirline_LSP",
                callback = function()
                    vim.schedule(function()
                        vim.cmd("LspInfo")
                    end)
                end,
            },
        }

        local Path = {
            -- inizializzazione del componente
            init = function(self)
                local bufname = vim.fn.expand("%")

                if bufname == "" then
                    -- buffer senza nome
                    self.path = "[No Name]"
                    self.filename = self.path
                    self.icon, self.icon_color = "", nil
                    return
                end

                -- percorso completo (con ~, relativo alla cwd se applicabile)
                self.path = vim.fn.fnamemodify(bufname, ":p:~:.")
                -- solo il nome del file (senza path)
                self.filename = vim.fn.fnamemodify(self.path, ":t")

                -- estensione
                local extension = vim.fn.fnamemodify(self.filename, ":e")

                -- icona + colore da nvim-web-devicons
                local ok, devicons = pcall(require, "nvim-web-devicons")
                if ok then
                    self.icon, self.icon_color = devicons.get_icon_color(self.filename, extension, { default = true })
                else
                    -- fallback se devicons non è disponibile
                    self.icon, self.icon_color = "", nil
                end
            end,

            -- highlight dell'icona (se vuoi che l’icona sia colorata)
            hl = function(self)
                if self.icon_color then
                    return { fg = self.icon_color, bold = true }
                else
                    return { fg = "blue", bold = true }
                end
            end,

            flexible = 1,

            {
                -- path completo
                provider = function(self)
                    local icon = self.icon and (" " .. self.icon .. " ") or " "
                    -- se vuoi lo slash finale SOLO su directory:
                    local trail = vim.fn.isdirectory(self.path) == 1 and "/" or ""
                    return icon .. self.path .. trail .. " "
                end,
            },
            {
                -- path abbreviato
                provider = function(self)
                    local icon = self.icon and (" " .. self.icon .. " ") or " "
                    local path = vim.fn.pathshorten(self.path)
                    local trail = vim.fn.isdirectory(self.path) == 1 and "/" or ""
                    return icon .. path .. trail .. " "
                end,
            },
            {
                -- nascosto
                provider = "",
            },
        }

        local Diagnostics = utils.surround({ " [", "]" }, nil, {
            condition = conditions.has_diagnostics,

            static = {
                error_icon = " ",
                warn_icon = " ",
                info_icon = " ",
                hint_icon = " ",
            },

            init = function(self)
                self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
                self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
                self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
                self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
            end,

            on_click = {
                name = "heirline_diagnostic",
                callback = function()
                    if is_available("telescope.nvim") then
                        require("telescope.builtin").diagnostics()
                    end
                end,
            },

            update = { "DiagnosticChanged", "BufEnter" },

            {
                provider = function(self)
                    return self.errors > 0 and (self.error_icon .. self.errors .. " ")
                end,
                hl = { fg = "red" },
            },
            {
                provider = function(self)
                    return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
                end,
                hl = { fg = "magenta" },
            },
            {
                provider = function(self)
                    return self.info > 0 and (self.info_icon .. self.info .. " ")
                end,
                hl = { fg = "green" },
            },
            {
                provider = function(self)
                    return self.hints > 0 and (self.hint_icon .. self.hints)
                end,
                hl = { fg = "blue" },
            },
        })

        local Location = {
            provider = "%3l:%-2v",
        }

        local ScrollBar = {
            static = {
                sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
            },
            provider = function(self)
                local curr_line = vim.api.nvim_win_get_cursor(0)[1]
                local lines = vim.api.nvim_buf_line_count(0)
                local i = math.floor(curr_line / lines * (#self.sbar - 1)) + 1
                return string.rep(self.sbar[i], 2)
            end,
            hl = function(self)
                return { fg = "yellow", bold = true }
            end,
        }

        local HelpFilename = {
            condition = function()
                return vim.bo.filetype == "help"
            end,
            provider = function()
                local filename = vim.api.nvim_buf_get_name(0)
                return vim.fn.fnamemodify(filename, ":t")
            end,
            hl = { fg = "blue", bold = true },
        }

        -- let's add the children to our FileNameBlock component
        FileNameBlock = utils.insert(
            FileNameBlock,
            FileIcon,
            utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
            unpack(FileFlags) -- A small optimisation, since their parent does nothing
        )

        ViMode = utils.surround({ "", "" }, function(self)
            return self:mode_color()
        end, { ViMode, hl = { fg = "grey14", bold = true } })

        Location = utils.surround({ "", "" }, function(self)
            return self:mode_color()
        end, { Location, Space, hl = { fg = "grey14", bold = true } })

        local DefaultStatusline = {
            ViMode,
            Space,
            GitBranch,
            Path,
            Diagnostics,
            Break,
            Align,
            LspClient,
            Align,
            FileType,
            Space,
            ScrollBar,
            Space,
            Location,
        }

        local SpecialStatusline = {
            condition = function()
                return conditions.buffer_matches({
                    filetype = { "NvimTree", "dbui", "packer", "startify", "fugitive", "fugitiveblame" },
                    buftype = { "nofile", "help", "quickfix", "terminal" },
                })
            end,
            FileType,
            { provider = "%q" },
            Space,
            HelpFilename,
            Align,
        }

        local StatusLines = {
            hl = function()
                return {
                    fg = "grey2",
                    bg = "bright_bg",
                }
            end,

            static = {
                mode_colors = {
                    n = "cyan",
                    i = "green",
                    v = "purple",
                    V = "purple",
                    ["\22"] = "purple", -- this is an actual ^V, type <C-v><C-v> in insert mode
                    c = "orange",
                    s = "magenta",
                    S = "magenta",
                    ["\19"] = "pink", -- this is an actual ^S, type <C-v><C-s> in insert mode
                    R = "red",
                    r = "red",
                    ["!"] = "red",
                    t = "green",
                },
                mode_color = function(self)
                    local mode = vim.fn.mode() or "n"
                    return self.mode_colors[mode]
                end,
            },

            fallthrough = false,
            SpecialStatusline,
            DefaultStatusline,
        }

        local CloseButton = {
            condition = function(self)
                return not vim.bo.modified and conditions.is_active()
            end,
            -- update = 'BufEnter',
            update = { "WinNew", "WinClosed", "BufEnter" },
            { provider = " " },
            {
                provider = "",
                hl = function()
                    if conditions.is_not_active() then
                        return { fg = "gray", force = true }
                    else
                        return { fg = "red", force = true }
                    end
                end,

                on_click = {
                    callback = function(_, minwid)
                        vim.api.nvim_win_close(minwid, true)
                    end,
                    minwid = function()
                        return vim.api.nvim_get_current_win()
                    end,
                    name = "heirline_winbar_close_button",
                },
            },
        }

        local WinBar = {
            init = function(self)
                self.bufnr = vim.api.nvim_get_current_buf()
            end,
            fallthrough = false,

            {
                -- Terminal WinBar rimane invariato perché ha un layout specifico
                condition = function()
                    return conditions.buffer_matches({ buftype = { "terminal" } })
                end,
                utils.surround({ "", "" }, "bright_bg", {
                    FileType,
                    Space,
                    TerminalName,
                    CloseButton,
                }),
            },

            {
                -- Inactive WinBar
                condition = function()
                    return not conditions.is_active()
                end,
                flexible = 1,
                {
                    -- Versione completa
                    {
                        BigSpace,
                        {
                            FileNameBlock,
                            hl = { fg = "gray", bold = true, force = true },
                        },
                        {
                            CloseButton,
                            provider = nil,
                            Align,
                            { provider = "" },
                            hl = { bg = "bg1", force = true },
                        },
                    },
                },
                {
                    -- Versione ridotta
                    {
                        Space,
                        {
                            FileNameBlock,
                            hl = { fg = "gray", bold = true, force = true },
                        },
                        CloseButton,
                    },
                },
                {
                    -- Versione minima
                    {
                        Space,
                        {
                            provider = function(self)
                                local filename = vim.fn.fnamemodify(self.filename, ":t")
                                return filename == "" and "[No Name]" or filename
                            end,
                            hl = { fg = "gray", bold = true, force = true },
                        },
                    },
                },
            },

            {
                -- Active WinBar
                flexible = 1,
                {
                    -- Versione completa
                    {
                        BigSpace,
                        {
                            FileNameBlock,
                            hl = { fg = "blue", bold = true, force = true },
                        },
                        {
                            CloseButton,
                            provider = nil,
                            Align,
                            { provider = "" },
                            hl = { bg = "bg1", force = true },
                        },
                    },
                },
                {
                    -- Versione ridotta
                    {
                        Space,
                        {
                            FileNameBlock,
                            hl = { fg = "blue", bold = true, force = true },
                        },
                        CloseButton,
                    },
                },
                {
                    -- Versione minima
                    {
                        Space,
                        {
                            provider = function(self)
                                local filename = vim.fn.fnamemodify(self.filename, ":t")
                                return filename == "" and "[No Name]" or filename
                            end,
                            hl = { fg = "blue", bold = true, force = true },
                        },
                    },
                },
            },
        }

        heirline.setup({
            statusline = StatusLines,
            -- winbar = WinBar, -- disabilitato: sostituito da incline.nvim (evita il nome file duplicato)
            opts = {
                -- if the callback returns true, the winbar will be disabled for that window
                -- the args parameter corresponds to the table argument passed to autocommand callbacks. :h nvim_lua_create_autocmd()
                disable_winbar_cb = function(args)
                    local buf = args.buf
                    local buftype =
                        vim.tbl_contains({ "prompt", "nofile", "help", "quickfix", "terminal" }, vim.bo[buf].buftype)
                    local filetype = vim.tbl_contains(
                        { "gitcommit", "fugitive", "Trouble", "lazy", "NvimTree", "neo%-tree" },
                        vim.bo[buf].filetype
                    )
                    return buftype or filetype
                end,
                -- Mappa i nomi dei colori che usi in Heirline ai tuoi colori personalizzati
                colors = {
                    bright_bg = colors.grey13,
                    bright_fg = colors.grey1,
                    red = colors.red,
                    green = colors.green,
                    blue = colors.blue,
                    gray = colors.grey7,
                    orange = colors.orange,
                    yellow = colors.yellow,
                    purple = colors.magenta,
                    cyan = colors.cyan,
                    pink = colors.pink,
                    magenta = colors.magenta,
                    bg = colors.bg,
                    bg1 = colors.bg1,
                    fg = colors.fg,
                    grey2 = colors.grey2,
                    grey8 = colors.grey8,
                    grey10 = colors.grey10,
                    grey13 = colors.grey13,
                    grey14 = colors.grey14,
                },
            },
        })

        vim.api.nvim_create_augroup("Heirline", { clear = true })
        -- TODO: vedere se questa opzione in Heirline serve
        vim.cmd([[au Heirline FileType * if index(['wipe', 'delete'], &bufhidden) >= 0 | set nobuflisted | endif]])

        vim.api.nvim_create_autocmd("ColorScheme", {
            callback = function(args)
                local updated_colors = require("sphynx.colors").get_color(args.match)
                utils.on_colorscheme({
                    bright_bg = updated_colors.grey13,
                    bright_fg = updated_colors.grey1,
                    red = updated_colors.red,
                    green = updated_colors.green,
                    blue = updated_colors.blue,
                    gray = updated_colors.grey7,
                    orange = updated_colors.orange,
                    yellow = updated_colors.yellow,
                    purple = updated_colors.magenta,
                    cyan = updated_colors.cyan,
                    pink = updated_colors.pink,
                    magenta = updated_colors.magenta,
                    bg = updated_colors.bg,
                    bg1 = updated_colors.bg1,
                    fg = updated_colors.fg,
                    grey2 = updated_colors.grey2,
                    grey8 = updated_colors.grey8,
                    grey10 = updated_colors.grey10,
                    grey13 = updated_colors.grey13,
                    grey14 = updated_colors.grey14,
                })
            end,
            group = "Heirline",
        })
    end,
}

return M
