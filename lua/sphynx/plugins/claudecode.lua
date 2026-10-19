--[[
===============================================================================================
Plugin: claudecode.nvim
===============================================================================================
Description: Integrazione "IDE" tra Neovim e Claude Code CLI. Neovim fa da editor (come
             l'estensione ufficiale VS Code/JetBrains): apre un server WebSocket locale e
             scrive un lockfile, cosi' una sessione Claude Code che gira in un terminale
             separato puo' connettersi e leggere selezione, file aperti e diagnostics.
Status: Active
Author: coder
Repository: https://github.com/coder/claudecode.nvim
Notes:
 - Caricamento lazy con event = "VeryLazy": il server parte subito dopo l'avvio (auto_start)
   e scrive il lockfile in ~/.claude/ide/<porta>.lock, necessario per il comando /ide
 - provider = "none": Neovim NON gestisce nessun terminale Claude. Claude Code gira nel TUO
   terminale esterno; i comandi :ClaudeCode/Open/Close non aprono nulla, ma server e tool
   (invio selezione, diff, diagnostics) restano attivi
 - Flusso d'uso: (1) apri Neovim sul progetto  (2) nel terminale dove Claude e' gia' avviato
   digiti /ide e selezioni "Neovim"  (3) selezioni il codice in Neovim e premi <leader>as
   per mandarlo come @-mention, poi scrivi la domanda nel terminale
 - Dipendenza folke/snacks.nvim NON inclusa: serve solo al provider "snacks" (terminale dentro
   Neovim); con provider "none" non e' richiesta. Se :checkhealth claudecode la reclama,
   aggiungerla in dependencies
 - Windows/MSYS: HOME diverge tra Neovim (C:/Users/...) e il claude di MSYS
   (D:/msys64/home/Sphynx). Il CLI usa CLAUDE_CONFIG_DIR = /d/msys64/home/Sphynx/.claude;
   in M.configs qui sotto forziamo la stessa CLAUDE_CONFIG_DIR per Neovim (solo se non gia'
   ereditata), cosi' lockfile e /ide puntano alla stessa cartella .claude/ide/
 - :checkhealth claudecode per verificare CLI, server, lockfile e stato della connessione
Keymaps:
 - <leader>as (visuale) → Manda la selezione a Claude (@-mention)
 - <leader>af (normale) → Aggiungi il file di nvim-tree al contesto (ClaudeCodeTreeAdd)
 - <leader>ac (normale) → Stato della connessione IDE
 - <leader>ay (normale) → Accetta la diff proposta (ClaudeCodeDiffAccept)
 - <leader>an (normale) → Rifiuta la diff proposta (ClaudeCodeDiffDeny)
 - <leader>am (normale) → Seleziona il modello di Claude (ClaudeCodeSelectModel)
 Comandi:
 - :ClaudeCodeSend           → Manda la selezione visuale a Claude
 - :ClaudeCodeStatus         → Stato di server e connessione
 - :ClaudeCodeStart / Stop   → Avvia/ferma il server WebSocket
 - :ClaudeCodeSelectModel    → Seleziona il modello (apre il terminale, no-op con provider none)
 - :ClaudeCodeAdd <file>     → Aggiunge un file al contesto di Claude
 - :ClaudeCodeTreeAdd        → Aggiunge al contesto il file selezionato in nvim-tree
 - :ClaudeCodeDiffAccept / :ClaudeCodeDiffDeny → Accetta/rifiuta una diff proposta
 - :ClaudeCodeCloseAllDiffs  → Chiude tutte le diff pendenti
TODO:
 - [ ] Verificare con :checkhealth claudecode che il lockfile finisca in D:/msys64/home/Sphynx/.claude/ide/
 - [ ] Valutare snacks.nvim + provider "snacks" se in futuro si vuole il terminale dentro Neovim
===============================================================================================
--]]

local M = {}

M.plugins = {
    ["claudecode"] = {
        "coder/claudecode.nvim",
        lazy = true,
        event = "VeryLazy", -- il server parte poco dopo l'avvio e scrive il lockfile per /ide
    },
}

M.setup = {
    ["claudecode"] = function()
        M.keybindings()
    end,
}

M.configs = {
    ["claudecode"] = function()
        -- Neovim (app Windows) e il claude di MSYS devono condividere la stessa cartella
        -- .claude/ide per il lockfile del comando /ide. Il CLI usa gia'
        -- CLAUDE_CONFIG_DIR = /d/msys64/home/Sphynx/.claude; se Neovim non eredita quella
        -- variabile (lancio fuori da MSYS) la impostiamo qui, cosi' il lockfile finisce
        -- dove il CLI lo cerca. Se invece nvim parte da MSYS la variabile c'e' gia' e non
        -- tocchiamo nulla.
        if not vim.env.CLAUDE_CONFIG_DIR or vim.env.CLAUDE_CONFIG_DIR == "" then
            if vim.fn.has("win32") == 1 then
                vim.env.CLAUDE_CONFIG_DIR = "D:/msys64/home/Sphynx/.claude"
            else
                vim.env.CLAUDE_CONFIG_DIR = vim.fn.expand("~/.claude")
            end
        end

        require("claudecode").setup({
            auto_start = true, -- avvia il server WebSocket all'avvio (scrive il lockfile in $CLAUDE_CONFIG_DIR/ide)
            terminal = {
                provider = "none", -- Neovim non gestisce il terminale: Claude gira nel TUO terminale esterno
            },
        })
    end,
}

M.keybindings = function()
    local mapping = require("sphynx.core.5-mapping")
    local wk = require("which-key")

    wk.add({
        { "<leader>a", group = "󰚩 Claude" },
    })

    mapping.register({
        {
            mode = { "v" },
            lhs = "<leader>as",
            rhs = [[<Cmd>ClaudeCodeSend<CR>]],
            options = { silent = true },
            description = "Manda la selezione a Claude",
        },
        {
            mode = { "n" },
            lhs = "<leader>af",
            rhs = [[<Cmd>ClaudeCodeTreeAdd<CR>]],
            options = { silent = true },
            description = "Aggiungi il file da nvim-tree al contesto",
        },
        {
            mode = { "n" },
            lhs = "<leader>ac",
            rhs = [[<Cmd>ClaudeCodeStatus<CR>]],
            options = { silent = true },
            description = "Stato connessione Claude IDE",
        },
        {
            mode = { "n" },
            lhs = "<leader>ay",
            rhs = [[<Cmd>ClaudeCodeDiffAccept<CR>]],
            options = { silent = true },
            description = "Accetta la diff proposta",
        },
        {
            mode = { "n" },
            lhs = "<leader>an",
            rhs = [[<Cmd>ClaudeCodeDiffDeny<CR>]],
            options = { silent = true },
            description = "Rifiuta la diff proposta",
        },
        {
            mode = { "n" },
            lhs = "<leader>am",
            rhs = [[<Cmd>ClaudeCodeSelectModel<CR>]],
            options = { silent = true },
            description = "Seleziona il modello di Claude",
        },
    })
end

return M
