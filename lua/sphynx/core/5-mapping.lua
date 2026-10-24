-- vim: set sw=2 ts=2 sts=2 et tw=120 foldmarker=--{{{,--}}} foldmethod=marker nospell:

-- mapleader/maplocalleader sono impostati in init.lua (devono precedere i plugin)

local mapping = {}
-- local wk = require("which-key")

--{{{ Function register
mapping.register = function(group_keymap)
    for _, key_map in pairs(group_keymap) do
        key_map.options.desc = key_map.description
        vim.keymap.set(key_map.mode, key_map.lhs, key_map.rhs, key_map.options)
    end
end
--}}} Function register

--{{{ Mapping preset option
mapping.opt_mappping = {
    mode = "n", -- NORMAL mode
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
}

mapping.opt_visual = {
    mode = "v", -- NORMAL mode
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
}

mapping.opt_mappping_localleader = {
    mode = "n", -- NORMAL mode
    prefix = "<localleader>",
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
}

mapping.opt_plugin = {
    mode = "n", -- NORMAL mode
    prefix = "<leader>",
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
}

mapping.opt_visual = {
    mode = "v", -- NORMAL mode
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
}

mapping.opt_plugin_visual = {
    mode = "v", -- NORMAL mode
    prefix = "<leader>",
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = true, -- use `nowait` when creating keymaps
}
--}}} Mapping preset option

--{{{ Global
if vim.fn.has("macunix") == 1 then
    vim.cmd([[let macvim_skip_cmd_opt_movement = 1]])
    -- macmeta esiste solo in MacVim: in Neovim l'opzione non c'e' e darebbe errore
    if vim.fn.exists("+macmeta") == 1 then
        vim.opt.macmeta = true
    end
    mapping.register({
        {
            mode = { "n", "v" },
            lhs = "<D-j>",
            rhs = "<M-j>",
            options = { silent = true },
        },
        {
            mode = { "n", "v" },
            lhs = "<D-k>",
            rhs = "<M-k>",
            options = { silent = true },
        },
    })
end
mapping.register({
    {
        mode = { "n" },
        lhs = "'",
        rhs = "`",
        options = { silent = true },
        description = "Remap ` for to go right position mark",
    },
    {
        mode = { "n" },
        lhs = "<localleader>w",
        rhs = [[:lcd %:p:h<cr>:pwd<CR>]],
        options = { silent = false },
        description = "Switch CWD to the directory of the open buffer",
    },
    {
        mode = { "n" },
        lhs = "<localleader>S",
        rhs = [[<CMD>setlocal spell!<CR>]],
        options = { silent = true },
        description = "Will toggle and untoggle spell checking",
    },
    { -- TODO: vedere se serve o lo posso togliere
        mode = { "i" },
        lhs = "<Esc>",
        rhs = "<Esc><Esc>",
        options = { silent = true },
        description = "Force esc two time",
    },
    {
        mode = { "n" },
        lhs = "<C-s>",
        rhs = [[<CMD>silent! update<CR>]],
        options = { silent = true },
        description = "Save silent mode",
    },
    {
        mode = { "v" },
        lhs = "<C-s>",
        rhs = [[<C-C><CMD>:silent! update<CR>]],
        options = { silent = true },
        description = "Save silent mode",
    },
    {
        mode = { "i" },
        lhs = "<C-s>",
        rhs = [[<Esc><CMD>:silent! update<CR>gi]],
        options = { silent = true },
        description = "Save silent mode",
    },
})
--}}} Global

--{{{ Folding
require("which-key").add({
    { "z", group = "󰊈 Folding" },
    { "z<Down>", "zr", desc = "Unfold 1 level fold" },
    { "z<Up>", "zm", desc = "Decrease 1 level fold" },
    { "z<Left>", "zc", desc = "Close current folding" },
    { "z<Right>", "zo", desc = "Open current folding" },
    { "z#", desc = "Set fold level to .N" },
    { "zf", '<CMD>lua require("sphynx.utils").toggle_fold()<CR>', desc = "Toggle foldclose automactly" },
    { "zh", "zfat", desc = "Html folding" },
    -- { "zz<Down>", "zR", desc = "Unfold all" },
    -- { "zz<Up>", "zM", desc = "Fold all" },
})

for i = 0, 10 do
    require("which-key").add({
        { "z" .. tostring(i), group = "󰊈 Folding", "<CMD>set foldlevel=" .. i .. "<CR>", hidden = true },
    })
end
--}}} Folding

--{{{ Moving around
mapping.register({
    {
        mode = { "n" },
        lhs = "9",
        rhs = "$",
        options = { silent = true },
        description = "󰑃 end of line",
    },
    {
        mode = { "n" },
        lhs = "0",
        rhs = "^",
        options = { silent = true },
        description = "󰑁 beginning of line",
    },
    {
        mode = { "n" },
        lhs = "8",
        rhs = function()
            local line = vim.api.nvim_win_get_cursor(0)[1]
            vim.api.nvim_win_set_cursor(0, { line, math.floor(vim.fn.virtcol("$") / 2) })
        end,
        options = { silent = true },
        description = "middle of line",
    },
})
--}}} Moving around

--{{{ Window
mapping.register({
    {
        mode = { "n" },
        lhs = "cp",
        rhs = ":pclose<CR>",
        options = { silent = true },
        description = "Close preview",
    },
    {
        mode = { "n" },
        lhs = "tn",
        rhs = [[<CMD>tabnew<CR>]],
        options = { silent = true },
        description = "Tab new",
    },
})

require("which-key").add({
    { "w", group = "󰆏 Window" },
    { "wc", "<C-W>c", desc = "Close current window" },
    { "w<Up>", "<C-W>k", desc = "Focus to window Up" },
    { "w<Down>", "<C-W>j", desc = "Focus to window Down" },
    { "w<Left>", "<C-W>h", desc = "Focus to window Left" },
    { "w<Right>", "<C-W>l", desc = "Focus to window Right" },
    { "wr", group = "󰙖 Resize" },
    { "wr<Up>", [[<CMD>resize +10<CR>]], desc = "Aumenta horizontal size" },
    { "wr<Down>", [[<CMD>resize -10<CR>]], desc = "Diminuisce horizontal size" },
    { "wr<Left>", [[<CMD>vertical resize -10<CR>]], desc = "Diminuisce vertical resize" },
    { "wr<Right>", [[<CMD>vertical resize +10<CR>]], desc = "Aumenta vertical resize" },
    { "wrh", "<C-w>|", desc = "Max horizontal size" },
    { "wrv", "<C-w>_", desc = "Max vertical size" },
    { "wr0", "<C-W>=", desc = "All equal space" },
    { "wn", group = "󰆏 New Window" },
    { "wn<Up>", [[<CMD>topleft new<CR>]], desc = "Up" },
    { "wn<Down>", [[<CMD>botright new<CR>]], desc = "Down" },
    { "wn<Left>", [[<CMD>topleft vnew<CR>]], desc = "Left" },
    { "wn<Right>", [[<CMD>botright vnew<CR>]], desc = "Right" },
    { "wm", group = "󰙕  Move" },
    { "wm<Up>", "<C-w>K", desc = "Up" },
    { "wm<Down>", "<C-w>J", desc = "Down" },
    { "wm<Left>", "<C-w>H", desc = "Left" },
    { "wm<Right>", "<C-w>L", desc = "Right" },
})
--}}} Window

--{{{ Buffer
require("which-key").add({
    { "b", group = " Buffers" },
    -- { "bC", [[<CMD>lua require("sphynx.ui.tabufline").close_buffer_and_window()<CR>]], desc = "Close buffer and window [tabufline]"},
    -- { "bc", [[<CMD>lua require("sphynx.ui.tabufline").close_buffer()<CR>]], desc = "Close buffer and keep window  [tabufline]"},
    { "bx", [[<CMD>lua require("sphynx.ui.tabufline").closeAllBufs()<CR>]], desc = "Close all buffers [tabufline]" },
    -- { "bC", [[<CMD>bd<CR>]], desc = "Close buffer and window" },
    -- { "bX", [[<CMD>bufdo bd<CR>]], desc = "Close all buffers" },
    { "bn", group = " New Buffer" },
    { "bn<Left>", [[<CMD>leftabove vnew<CR>]], desc = "Left" },
    { "bn<Right>", [[<CMD>rightbelow vnew<CR>]], desc = "Right" },
    { "bn<Up>", [[<CMD>leftabove new<CR>]], desc = "Up" },
    { "bn<Down>", [[<CMD>rightbelow new<CR>]], desc = "Down" },
})
--}}} Buffer

--{{{ Tab-Workspace
--
--}}} Tab-Workspace

--{{{ Editing
mapping.register({
    -- TODO: vedere se lo devo fare solo per ruby
    {
        mode = { "i" },
        lhs = "<C-d>",
        rhs = "<C-O>B<C-O>dE",
        options = { silent = true },
        description = "Eliminare parola @variabile o se mi (trova) al centro della parola",
    },
    {
        mode = { "n" },
        lhs = "<localleader>D",
        rhs = "BdEi",
        options = { silent = true },
        description = "Eliminare parola @variabile o se mi (trova) al centro della parola",
    },
    {
        mode = { "n" },
        lhs = "<localleader>C",
        rhs = "Bye",
        options = { silent = true },
        description = "Copia parola @variabile o se mi (trova) al centro della parola",
    },

    -- TODO: vedere se usare plugin surround.nvim| Surround.vim | vim-sandwich
    -- TODO: per ora queste funzioni le ho disabilitate mi davano problemi con visual selection copiare su i registri
    -- {
    --   mode = { "x" },
    --   lhs = "(",
    --   rhs = [[<ESC>:let p = &paste<CR>:set paste<CR>:let a = line2byte(line('.')) + col('.')<CR>gvc()<ESC>:if getregtype() ==# 'V'<CR>call setreg('"', substitute(@", '\n$', '', ''), 'c')<CR>endif<CR>P:exe "goto ".a<CR>:exe "let &paste=".p<CR>]],
    --   options = { silent = true },
    --   description = "Mette parentesi tonde sul testo selezionato",
    -- },
    -- {
    --   mode = { "x" },
    --   lhs = "[",
    --   rhs = [[<ESC>:let p = &paste<CR>:set paste<CR>:let a = line2byte(line('.')) + col('.')<CR>gvc[]<ESC>:if getregtype() ==# 'V'<CR>call setreg('"', substitute(@", '\n$', '', ''), 'c')<CR>endif<CR>P:exe "goto ".a<CR>:exe "let &paste=".p<CR>]],
    --   options = { silent = true },
    --   description = "Mette parentesi quadre sul testo selezionato",
    -- },
    -- {
    --   mode = { "x" },
    --   lhs = "\"",
    --   rhs = [[<ESC>:let p = &paste<CR>:set paste<CR>:let a = line2byte(line('.')) + col('.')<CR>gvc""<ESC>:if getregtype() ==# 'V'<CR>call setreg('"', substitute(@", '\n$', '', ''), 'c')<CR>endif<CR>P:exe "goto ".a<CR>:exe "let &paste=".p<CR>]],
    --   options = { silent = true },
    --   description = "Mette doppio  apice esul testo selezionato",
    -- },
    -- {
    --   mode = { "x" },
    --   lhs = "\'",
    --   rhs =[[<ESC>:let p = &paste<CR>:set paste<CR>:let a = line2byte(line('.')) + col('.')<CR>gvc''<ESC>:if getregtype() ==# 'V'<CR>call setreg('"', substitute(@", '\n$', '', ''), 'c')<CR>endif<CR>P:exe "goto ".a<CR>:exe "let &paste=".p<CR>]],
    --   options = { silent = true },
    --   description = "Mette singolo  apice esul testo selezionato",
    -- },
})
--}}} Editing

--{{{ Editing
mapping.register({
    -- TODO: vedere se lo devo fare solo per ruby
    {
        mode = { "i", "n" },
        lhs = "<C-a>",
        rhs = "<Esc>ggVG",
        options = { silent = true },
        description = "Select all buffer",
    },
})
--}}} Editing

--{{{ Ctags
require("which-key").add({
    { "t", group = " Tags" },
    { "t<Left>", "<C-T>", desc = "Go back from definition" },
    -- g<C-]> = tjump del simbolo sotto il cursore CON contesto posizione: il tagfunc
    -- nativo LSP fa una vera "go to definition" invece della ricerca fuzzy
    -- workspace/symbol che scatta quando riceve solo il nome da un comando ex
    { "t<Right>", "g<C-]>", desc = "Jump to the definition" },
    { "tv", [[<CMD>vsp<CR>g<C-]>]], desc = "Jump to the definition vsplit" },
    { "ts", [[<CMD>sp<CR>g<C-]>]], desc = "Jump to the definition split" },
})
--}}} Ctags

--{{{ Visualization
mapping.register({
    {
        mode = { "n" },
        lhs = "<localleader>-",
        rhs = [[:nohlsearch<CR>]],
        options = { silent = false },
        description = "Clear search highlight",
    },
})
require("which-key").add({
    { "<localleader>c", desc = "Toggle cursorline cursorcolumn" },
    { "<localleader>cl", [[<CMD>set cursorline! <CR>]], desc = "Toggle highlight cursorline" },
    { "<localleader>cc", [[<CMD>set cursorcolumn! <CR>]], desc = "Toggle highlight cursorcolumn" },
    {
        "<localleader>ca",
        [[<CMD>set cursorcolumn!  cursorline! <CR>]],
        desc = "Toggle highlight cursorcolumn and cursorline",
    },
})
--}}} Visualization

--{{{ Search & Replace
mapping.register({
    {
        mode = { "n" },
        lhs = "<localleader>r",
        rhs = [[:%s/\<<C-r>=expand("<cword>")<CR>\>/]],
        options = { silent = false },
        description = "Replace all occurrence word",
    },
})
--}}} Search & Replace

--{{{ Copy & Paste
-- copio current file and line to clipboard
-- utile da usare con pry, per settare brekpoint
-- :break app/actions/forecast/connect_excel.rb:36
mapping.register({
    {
        mode = { "n" },
        lhs = "<localleader>y",
        rhs = [[:let @+=substitute(fnamemodify(expand("%"), ":~:."),"\\","/", "g") . ':' . line(".")<CR>]],
        options = { silent = false },
        description = "Copy current file and line to clipboard",
    },
})
--}}} Copy & Paste

--{{{ QuickFix
mapping.register({
    {
        mode = { "n" },
        lhs = "<F5>",
        rhs = [[<CMD>lua require("sphynx.utils").toggle_qf()<CR>]],
        options = { silent = false },
        description = "Toggle quickfix",
    },
})
mapping.register({
    {
        mode = { "n" },
        lhs = "<F6>",
        rhs = [[<CMD>cclose<CR>]],
        options = { silent = false },
        description = "Close quickfix",
    },
})
--}}} QuickFix

--{{{ Neovim Configuration
require("which-key").add({
    { "<leader>n", group = " Neovim" },
    { "<leader>ni", "<CMD>e " .. sphynx.path.nvim_config .. "/init.lua<CR>", desc = "Mi apre subito il init.lua" },
    {
        "<leader>nc",
        "<CMD>e " .. sphynx.path.nvim_config .. "/lua/sphynx/core/init.lua<CR>",
        desc = "Mi apre subito il core/init.lua",
    },
    {
        "<leader>nm",
        "<CMD>e " .. sphynx.path.nvim_config .. "/lua/sphynx/core/5-mapping.lua<CR>",
        desc = "Mi apre subito il core/5-mapping.lua",
    },
    {
        "<leader>np",
        "<CMD>e " .. sphynx.path.nvim_config .. "/lua/sphynx/core/3-plugins.lua<CR>",
        desc = "Mi apre subito il core/3-plugins.lua",
    },
    { "<leader>ng", "<CMD>e " .. sphynx.path.nvim_config .. "/ginit.vim<CR>", desc = "Mi apre subito il ginit.vim" },
})
--}}} Neovim Configuration

--{{{ Git
-- Gruppo Git condiviso da gitsigns (hunk) e diffview (viste diff): dichiarato qui
-- una sola volta per evitare il duplicato segnalato dal checkhealth di which-key.
-- Le keymap effettive restano nei rispettivi file di plugin.
require("which-key").add({
    { "<leader>g", group = " Git" },
})
--}}} Git

return mapping
