--{{{ Modeline and Notes
-- vim: set sw=2 ts=2 sts=2 et tw=120 foldmarker=--{{{,--}}} foldmethod=marker nospell:

--{{{ Header
--[[
            Maintainer:
                miboscol@gmail.com
            Version:
                2.0 - 10/11/15 09:26:00
            Blog_post:
                http:/.............
            Sections:
                -> General
                    -> Identify platform
                    -> Stratup Vim-Plug
                    -> Environment
                        -> Files, backups and undo
                        -> Tab and indent relate
                        -> Folding
                -> UI Setting
                -> Key Setting
                -> Shortcut => Folding
                -> Shortcut => Moving aroundg
                -> Shortcut => Buffer & window
                -> Shortcut => Editing
                -> Shortcut => Visualization
                -> Shortcut => Search & Replace
                -> Shortcut => Ctags
                -> Shortcut => Diff mode
                -> Language Support
                    -> Ruby & Rails
                    -> Xml
                -> Plugin
                    -> Airline
                    -> AutoFormat
                    -> CtrlSpace
                    -> Dash
                    -> EasyTag
                    -> GoldenView
                    -> IndentLine
                    -> MakeHeader
                    -> Maximizer
                    -> NerdTree
                    -> Signature
                    -> Tabular
                    -> Tagbar
                    -> Tcomment
                    -> Ultisnip
                -> Autocmd
                -> Helper functions
            --]]
--}}} Header

--}}} Modeline and Notes

local cmd = vim.cmd

--{{{ Identify platform
local is_osx = function()
    return (vim.fn.has("macunix") == 1)
end
local is_linux = function()
    return ((vim.fn.has("unix") == 1) and not (vim.fn.has("macunix") == 1) and not (vim.fn.has("win32unix") == 1))
end
local is_windows = function()
    return ((vim.fn.has("win16") == 1) or (vim.fn.has("win32") == 1) or (vim.fn.has("win64") == 1))
end

vim.g.is_nvim = (vim.fn.has("nvim") == 1)
vim.g.is_nvim_qt = (vim.fn.exists("*nvim_list_uis") == 1) and (vim.api.nvim_list_uis()[1]["chan"] == 1)
vim.g.is_gui_running = (vim.fn.has("gui_running") == 1) or vim.g.is_nvim_qt
--}}} Identify platformgui_runn

--{{{ Set before all
cmd([[let did_install_default_menus=1]])
cmd([[let did_install_syntax_menu=1]])
-- Disabilito il vimrc che in vim 8 veniva caricato di default
vim.cmd([[let skip_defaults_vim=1]])
vim.opt.termguicolors = true -- True color support
vim.opt.mouse = "a" -- enable mouse mode
vim.g.local_config = vim.fn.expand("./vim-dev")
if vim.fn.filereadable(vim.g.local_config) ~= 0 then
    print("Leggo file vimrc locale")
    cmd("source " .. vim.g.local_config)
end
--}}} Set before all

--{{{ General

--{{{ Windows Config
if is_windows() then
    -- Load windows support
    vim.cmd("source " .. vim.fn.expand(sphynx.path.nvim_config .. "/mswin.vim"))
end
--}}} Windows Config

--{{{ Global
-- Sets how many lines of history has to remember
vim.opt.history = 200
-- '1000: Salva fino a 1000 comandi nella cronologia.
--  <150: Salva fino a 150 righe di ricerca.
-- s30: Salva lo stato per 30 sessioni di Neovim.
-- h: Mantieni la cronologia anche dopo il riavvio.
vim.opt.shada = "'1000,<150,s30,h"
-- Backspace and cursor keys wrap too
vim.opt.whichwrap:prepend("h,l")
-- Ignore case when searching
vim.opt.ignorecase = true
-- When searching try to be smart about cases
vim.opt.smartcase = true
-- timeoutlen: timeout insert key
vim.opt.timeoutlen = 300
-- abilito il controllo ortografico
-- vim.opt.spell = true
-- Set English and Italian language
vim.opt.spelllang = { "it", "en" }
-- Cerca la documentazione in italiano se presente altrimenti in inglese
vim.opt.helplang = { "it", "en" }
-- Now, when using :sb, :sbnext, :sbprev instead of :b, :bnext, :bprev to switch buffers, Vim will check if buffer is open in tab/window and switch to that tab/window
vim.opt.switchbuf = "usetab"
-- di default era .,w,b,u,
-- . => scan the current buffer ('wrapscan' is ignored)
-- w => scan buffers from other windows
-- b => scan other loaded buffers that are in the buffer list
-- t => tag completion
-- u => scan the unloaded buffers that are in the buffer list
-- i => scan current and included files
-- k => scan the files given with the 'dictionary'
vim.opt.complete = { ".", "w", "b", "u" }
-- non fa vedere la tilde alla fine del file; "fold: " rimuove i caratteri ----- dopo il fold
vim.opt.fillchars = { eob = " ", vert = "│", fold = " " }
-- vim.opt.fillchars = {
--         eob = " "      ,
--         horiz     = '━',
--         horizup   = '┻',
--         horizdown = '┳',
--         vert      = '┃',
--         vertleft  = '┫',
--         vertright = '┣',
--         verthoriz = '╋',
--       }
-- "▏" │" "▎" "⎸"" "¦" "┆" "" "┊"
-- "▏" │" "▎" "⎸"" "¦" "┆" "" "┊"
-- disabilito plugin caricati di default
local disabled_built_ins = {
    "2html_plugin",
    "getscript",
    "getscriptPlugin",
    "gzip",
    "logipat",
    "netrw",
    "netrwPlugin",
    "netrwSettings",
    "netrwFileHandlers",
    "matchit",
    "matchparen",
    "man",
    "tar",
    "tarPlugin",
    "rrhelper",
    "spellfile_plugin",
    "vimball",
    "vimballPlugin",
    "zip",
    "zipPlugin",
    "loaded_less",
    "loaded_syntax_completion",
    "tutor_mode_plugin",
    "syntax_completion",
    "sql_completion",
    "rrhelper",
}
for _, plugin in pairs(disabled_built_ins) do
    vim.g["loaded_" .. plugin] = 1
end

-- sync with system clipboard
vim.opt.clipboard = "unnamedplus"
-- confirm to save changes before exiting modified buffer
vim.opt.confirm = true
vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"
-- preview incremental substitute
vim.opt.inccommand = "split"
-- No double spaces with join after a dot
vim.opt.joinspaces = false
-- Lines of context
vim.opt.scrolloff = 5
-- Columns of context
vim.opt.sidescrolloff = 8
-- Jump 5 lines when running out of the screen
vim.opt.scrolljump = 5
-- Round indent
vim.opt.shiftround = true
-- List of words that change the behavior of the |jumplist|
vim.opt.jumpoptions = "stack"
-- Time in milliseconds to wait for a key code sequence to complete
vim.opt.ttimeoutlen = 10
-- When "on" the commands listed below move the cursor to the first non-blank of the line.  When off the cursor is kept in the same column (if possible).
vim.opt.startofline = true
-- allows users to select what, if any, types of embedded script highlighting they wish to have.
-- g:vimsyn_embed == 0      : disable (don't embed any scripts)
-- g:vimsyn_embed == 'lPr'  : support embedded lua, python and ruby
vim.g.vimsyn_embed = "l"
-- permette di cancellare in modo fluido attraverso indentazioni, fine riga e punto di inizio inserimento
vim.opt.backspace = { "indent", "eol", "start" }
-- consente di muovere il cursore oltre l'inizio e la fine delle righe usando i tasti freccia e di movimento
vim.opt.whichwrap:append("<,>,[,]")

--}}} Global

--{{{ UI Setting
vim.opt.shortmess = "IToOlxfitncWF"
-- set the terminal's title
vim.opt.title = true
-- dont show mode since we have a statusline
vim.opt.showmode = false
-- Setta per ogni buffer l'opzione hidden di default, questo mi permette di passare in
-- maniera più pratica tra i buffer(ved. usr_22: nascondere i buffer)
vim.opt.hidden = true
-- show line number
vim.opt.number = true
-- Command-line completion mode
vim.opt.wildmode = "longest:full,full"
-- file da ignorare nel wildmenu
vim.opt.wildignore = {
    "*.o",
    "*~",
    "*.pyc",
    "*.png",
    "*.jpg",
    "*.gif",
    "*.xlsm",
    "*.xls",
    "*.xlsx",
    "*.zip",
    "*.so",
    "*.exe",
    "*.ico",
    "*.lock",
    "log/**",
    "*\\log\\*",
    "*/log/*",
    "vendor/cache/**",
    "vendor/rails/**",
    "*\\tmp\\*",
    "*/tmp/*",
    "*/.git/*",
    ".git",
    ".git/*",
    "*\\.git\\*",
    "*/node_modules/**",
    "*/node_modules_custom/**",
    "Neovim Doc/**",
    ".bundle",
    ".yardoc",
    ".prettierrc",
}
-- Put new windows below current
vim.opt.splitbelow = true
-- Put new windows right of current
vim.opt.splitright = true
-- vim.opt.winheight = 10
-- vim.opt.winminheight = 4
-- vim.opt.winwidth = 40
-- vim.opt.winminwidth = 18
-- setto la trasparenza del pum
vim.opt.pumblend = 10
-- setto la trasparenza dell preview window
vim.opt.winblend = 5
-- Maximum number of entries in a popup
vim.opt.pumheight = 10
-- Always show the signcolumn, se metto "number" al posto di "yes"
-- mostra i sign nella colonna dei numer
vim.opt.signcolumn = "yes"
--}}} UI Setting

--{{{ Increase Perfomance
-- migliora le performance di neovim
cmd([[syntax sync maxlines=10000]])
cmd([[syntax sync minlines=100]])
vim.opt.cursorcolumn = false
vim.opt.cursorline = false
vim.opt.synmaxcol = 370
-- Don't redraw while executing macros (good performance config)
vim.opt.lazyredraw = true
vim.opt.ruler = false
vim.opt.showcmd = false
-- Time in milliseconds for redrawing the display
vim.opt.redrawtime = 1500
--}}} Increase Perfomance

--{{{ Files, backups and undo, Save
-- Fine-riga: preferisci LF (unix) anche su Windows, per coerenza cross-platform
-- e per non reintrodurre CRLF nei file nuovi. I file esistenti mantengono il
-- formato gia' rilevato; i file nuovi nascono con LF.
vim.opt.fileformats = { "unix", "dos" }
-- Turn backup off
vim.opt.writebackup = false
vim.opt.swapfile = false
-- Persistent undo
vim.opt.undofile = true
vim.opt.undolevels = 200
vim.opt.sessionoptions = {
    "buffers", -- Buffer nascosti
    "curdir", -- Directory di lavoro corrente
    "folds", -- Stato delle fold
    "globals", -- Variabili globali (iniziano con maiuscola)
    "help", -- Finestre della guida
    "localoptions", -- Opzioni locali di buffer e finestre
    "options", -- Opzioni globali
    "resize", -- Dimensioni delle finestre
    "tabpages", -- Tab pages
    "terminal", -- Terminali
    "winpos", -- Posizione finestra Vim
    "winsize", -- Dimensione finestra
    "slash", -- Backslashes in nomi file
    "unix", -- File endings
}
-- vim.opt.sessionoptions = { "blank", "buffers", "curdir", "folds", "help", "tabpages", "winsize", "resize", "winpos", "terminal" }
--}}} Files, backups and undo

--{{{ Tab and indent
-- Use spaces instead of tabs
vim.opt.expandtab = true
-- 1 tab == 2 spaces
-- vim.opt.shiftwidth = 2
-- vim.opt.tabstop = 2
-- vim.opt.softtabstop = 2
-- Insert indents automatically
vim.opt.autoindent = true
vim.opt.smartindent = true
--}}} Tab and indent

--{{{ Folding
-- deepest fold is 10 levels
vim.opt.foldnestmax = 10
-- cosa viene visualizzato quando faccio il folding del codice
-- vim.opt.foldtext = "v:lua.custom_fold_text()"
-- fare l'unfold automatico
vim.opt.foldopen:append("insert")
-- setto il default foldlevel quando apro un file
-- TODO: vedere se serve lasciarlo o toglierlo
vim.opt.foldlevel = 99
-- TODO: Uso il plugin Ufo se funziona corretamente rimuovere queste due righe
-- vim.opt.foldexpr = "v:lua.require'sphynx.utils.folding'.foldexpr()"
-- vim.opt.foldmethod = "expr"
--}}} Folding

--{{{ Visualizzazione
-- Hide * markup for bold and italic
vim.opt.conceallevel = 0
-- Hide * markup for bold and italic
vim.opt.concealcursor = ""
-- Show some invisible characters (tabs...
-- TODO: vedere se lasciarlo
vim.opt.list = true
-- vim.opt.listchars = {eol = '↲', tab = '▸ ', trail = '·', space = "."}
--}}} Visualizzazione

--}}} General

--{{{ Markdown
-- Use proper syntax highlighting in code blocks
-- local fences = {
--   "lua",
--   "vim",
--   "json",
--   "typescript",
--   "javascript",
--   "js=javascript",
--   "ts=typescript",
--   "shell=sh",
--   "python",
--   "sh",
--   "console=sh",
--   "go",
--   "ruby",
--   "html",
-- }
-- vim.g.markdown_fenced_languages = fences

-- -- plasticboy/vim-markdown
-- vim.g.vim_markdown_folding_level = 10
-- vim.g.vim_markdown_fenced_languages = fences
-- vim.g.vim_markdown_folding_style_pythonic = 1
-- vim.g.vim_markdown_conceal_code_blocks = 0
-- vim.g.vim_markdown_conceal = 0
-- vim.g.vim_markdown_folding_style_pythonic = 1
-- vim.g.vim_markdown_frontmatter = 1
-- vim.g.vim_markdown_strikethrough = 1
--}}} Markdown

--{{{ Abbreviation
-- cmd([[ab todo # @TODO:]])
cmd([[ab <silent> bp binding.pry<C-o>]])
cmd([[cnoreabbrev LS LspStart]])
cmd([[cnoreabbrev LAS Lazy show]])
cmd([[cnoreabbrev LAC Lazy check]])
cmd([[cnoreabbrev LAU Lazy update]])
--}}} Abbreviation

--{{{ Nvim Provider

--{{{ Node
-- vim.g.node_host_prog = "C:/Program Files/nodejs/node_modules/neovim/bin/cli.js"
--}}} Node

--{{{ Python2
vim.g.loaded_python_provider = 0
--}}} Python2

--{{{ Python3
-- vim.g.loaded_python3_provider = 0
if not vim.g.loaded_python3_provider then
    -- exepath() restituisce il path raw dell'eseguibile (no shell spawn, no fnameescape)
    local python3_host_prog = vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or vim.fn.exepath("python")

    if python3_host_prog ~= "" and vim.fn.filereadable(python3_host_prog) == 1 then
        vim.g.python3_host_prog = python3_host_prog
        vim.opt.pyxversion = 3
    else
        vim.notify("Python3 non trovato. Installa python3 e pynvim.", vim.log.levels.WARN, { title = "Python3 Provider" })
    end
end
--}}} Python3

--{{{ Ruby
vim.g.loaded_ruby_provider = 0
if not vim.g.loaded_ruby_provider then
    if vim.fn.executable("neovim-ruby-host") == 1 then
        vim.g.ruby_host_prog = vim.fn.exepath("neovim-ruby-host")
    else
        vim.notify("Gemma neovim-ruby-host non trovata nel tuo PATH.", vim.log.levels.WARN, { title = "Ruby Provider" })
    end
end
--}}} Ruby

--{{{ Perl
vim.g.loaded_perl_provider = 0
--}}} Perl

--}}} Nvim Provider

--{{{ Other Gui

if vim.g.nvy then
    -- vim.opt.guifont = "DejaVuSansM Nerd Font:h9:cANSI:qDraft"
    vim.opt.guifont = "FiraCode Nerd Font:h9:cANSI:qDraft"
    -- vim.opt.guifont = "JetBrainsMonoNL Nerd Font Mono:h9:cANSI:qDraft"
    -- vim.opt.guifont = "JetBrainsMono Nerd Font:h9:cANSI:qDraft"
    -- vim.opt.guifont = "MonaspiceNE Nerd Font:h9:cANSI:qDRAFT"
end

if vim.g.neovide then
    -- vim.opt.guifont = "DejaVuSansM Nerd Font:h9:cANSI:qDRAFT"
    -- vim.opt.guifont = "FiraCode Nerd Font:h9:cANSI:qDraft"
    -- vim.opt.guifont = "MonaspiceNE Nerd Font:h9"
    vim.opt.linespace = 1
    vim.g.neovide_scroll_animation_length = 0
    vim.g.neovide_refresh_rate = 120
    vim.g.neovide_cursor_antialiasing = true
    vim.g.neovide_cursor_animation_length = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_cursor_vfx_mode = ""
    vim.g.neovide_unlink_border_highlights = true
    vim.g.neovide_padding_top = 2
    vim.g.neovide_padding_bottom = 2
    vim.g.neovide_padding_right = 2
    vim.g.neovide_padding_left = 2
    vim.g.neovide_window_blurred = false
    vim.g.neovide_opacity = 1
    vim.g.neovide_normal_opacity = 1
    vim.g.neovide_pixel_geometry = "RGBH"
    vim.g.neovide_text_gamma = 0.0
    vim.g.neovide_text_contrast = 0.5
    cmd("imap <M-Esc> [")
    cmd("imap <M-C-]> ]")

    -- Drag&drop file: comportamento deterministico "salta se gia aperto".
    -- Di default Neovide chiama neovide.private.dropfile(filename, tabs) ed esegue
    -- `:drop`; quando il lato Rust passa tabs=true fa `:<N>tab drop`, aprendo un
    -- nuovo tab in fondo -> incompatibile con workspace.vim (tab e [No Name] spuri).
    -- Override: ignoriamo `tabs` e usiamo sempre `:drop` semplice. Con
    -- switchbuf=usetab questo salta al tab se il file e' gia aperto in un
    -- workspace, altrimenti lo apre nella finestra/workspace corrente. Mai nuovi tab.
    local function patch_neovide_dropfile()
        if _G.neovide and _G.neovide.private then
            _G.neovide.private.dropfile = function(filename)
                vim.api.nvim_cmd({
                    cmd = "drop",
                    args = { vim.fn.fnameescape(filename) },
                }, {})
            end
            return true
        end
        return false
    end
    -- Il runtime Lua di Neovide viene iniettato via RPC dopo l'attach dell'UI,
    -- quindi puo' non essere pronto durante lo startup: ritenta per ~2s.
    if not patch_neovide_dropfile() then
        local tries = 0
        local timer = vim.uv.new_timer()
        timer:start(
            50,
            50,
            vim.schedule_wrap(function()
                tries = tries + 1
                if patch_neovide_dropfile() or tries > 40 then
                    timer:stop()
                    timer:close()
                end
            end)
        )
    end

    -- Helper function for transparency formatting
    -- local alpha = function()
    --   return string.format("%x", math.floor(255 * vim.g.transparency or 0.8))
    -- end
    -- -- g:neovide_transparency should be 0 if you want to unify transparency of content and title bar.
    -- vim.g.neovide_transparency = 0
    -- vim.g.transparency = 1
    -- vim.g.neovide_background_color = "#0f1117" .. alpha()
end

if vim.g.gonvim_running then
    vim.opt.ruler = false
    vim.opt.laststatus = 0
    vim.opt.showcmd = false
end
--}}} Other Gui

--{{{ Linux
if vim.fn.has("unix") == 1 or vim.fn.has("win32") == 1 then
    require("sphynx.utils.dragopen").setup()
end
--}}} Linux

--{{{ Test
-- This is a sequence of letters which describes how automatic formatting is to be done
-- TAG:[#comment #format] Ho disabilitato che mi crea la riga commentata automaticamente, se viglio aggiungerla devo aggiungere la "o"
vim.opt.formatoptions = "1jcrql"
-- Virtual editing means that the cursor can be positioned where there is no actual character.
vim.opt.virtualedit = "block"
-- VimL support fold autogroup and function
vim.g.vimsyn_folding = "af"

vim.opt.cmdheight = 0

vim.opt.splitkeep = "screen"

vim.g.editorconfig = false

vim.opt.smoothscroll = true

-- Configurazione base per il wrapping
vim.opt.wrap = true -- Abilita il wrapping
vim.opt.linebreak = true -- Wrap alle parole invece che ai caratteri
vim.opt.breakindent = true -- Mantiene l'indentazione nel wrap
vim.opt.display = "lastline" -- Mostra il più possibile dell'ultima linea
vim.opt.textwidth = 0 -- Disabilita la formattazione automatica
vim.opt.wrapmargin = 0 -- Disabilita il margine di wrapping

-- Crea comandi utili per gestire il wrapping
vim.api.nvim_create_user_command("ToggleWrap", function()
    vim.opt_local.wrap = not vim.opt_local.wrap:get()
    print("Wrap è " .. (vim.opt_local.wrap:get() and "attivo" or "disattivo"))
end, {})

--}}} Test

-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()" -- TreeSitter folding
-- vim.opt.foldmethod = "expr" -- TreeSitter folding
-- vim.cmd([[let g:prosession_last_session_dir = $HOME . '/.dotfiles/vimfiles/session_nvim']])
-- vim.cmd([[let g:prosession_dir = $HOME . '/.dotfiles/vimfiles/session_nvim']])
-- vim.cmd([[:let g:prosession_dir = 'C:\Users\en27553\.vim\session\']])

-- salvataggio automatico dei file
-- vim.cmd([[autocmd WinLeave,FocusLost  *
--             \   if &ft!=""
--             \   && &ft!="nerdtree"
--             \   && &ft!="qf"
--             \   && &ft!="vim-plug"
--             \   && !&readonly
--             \   && (filereadable(expand('%')) == 1)
--             \ | silent write
--             \ | endif]])
